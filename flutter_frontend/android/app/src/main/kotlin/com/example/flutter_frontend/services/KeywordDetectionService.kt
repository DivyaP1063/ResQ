package com.example.flutter_frontend.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.flutter_frontend.MainActivity
import com.example.flutter_frontend.R
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.nio.ByteBuffer
import java.nio.ByteOrder
import ai.picovoice.porcupine.Porcupine
import ai.picovoice.porcupine.PorcupineException
import com.example.flutter_frontend.BuildConfig

/**
 * Foreground service for continuous keyword detection
 * Monitors audio input for emergency keywords even when app is closed
 */
class KeywordDetectionService : Service() {
    
    companion object {
        private const val TAG = "KeywordDetectionService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "keyword_detection_channel"
        
        // Porcupine configuration - API key loaded from BuildConfig
        private val ACCESS_KEY = BuildConfig.PICOVOICE_ACCESS_KEY
        
        // Audio configuration - Porcupine requires 16kHz, 16-bit PCM
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val BUFFER_SIZE_FACTOR = 2
        
        // Event sink for communication with Flutter
        var eventSink: EventChannel.EventSink? = null
    }
    
    // Service components
    private var audioRecord: AudioRecord? = null
    private var isDetecting = false
    private var wakeLock: PowerManager.WakeLock? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    // Porcupine keyword detection
    private var porcupine: Porcupine? = null
    private lateinit var audioBuffer: ShortArray
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "KeywordDetectionService created")
        
        // Initialize notification channel
        createNotificationChannel()
        
        // Acquire wake lock to prevent device from sleeping
        acquireWakeLock()
        
        // Initialize Porcupine keyword detector
        initializePorcupine()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "KeywordDetectionService started")
        
        // Start foreground service with persistent notification
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Start keyword detection
        startKeywordDetection()
        
        // Return START_STICKY to restart service if killed by system
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null // This is a started service, not bound
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "KeywordDetectionService destroyed")
        
        // Clean up resources
        stopKeywordDetection()
        releaseWakeLock()
        cleanupPorcupine()
        serviceScope.cancel()
    }
    
    /**
     * Creates notification channel for Android O+ compatibility
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Emergency Keyword Detection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors for emergency keywords in the background"
                setSound(null, null) // Silent notification
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Creates persistent notification for foreground service
     */
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ResQ Emergency Detection")
            .setContentText("Listening for emergency keywords...")
            .setSmallIcon(R.drawable.ic_notification) // You'll need to add this icon
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Prevents user from dismissing
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    /**
     * Acquires wake lock to keep CPU awake for audio processing
     */
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$TAG:KeywordDetectionWakeLock"
        ).apply {
            acquire(10 * 60 * 1000L /*10 minutes*/)
        }
    }
    
    /**
     * Releases wake lock
     */
    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
    }
    
    /**
     * Initializes Porcupine keyword detection engine
     */
    private fun initializePorcupine() {
        try {
            // Initialize Porcupine with available built-in keywords that could indicate emergency
            porcupine = Porcupine.Builder()
                .setAccessKey(ACCESS_KEY)
                .setKeywords(arrayOf(
                    Porcupine.BuiltInKeyword.ALEXA,     // "Alexa" - can be used as emergency trigger
                    Porcupine.BuiltInKeyword.COMPUTER,  // "Computer" - emergency trigger  
                    Porcupine.BuiltInKeyword.HEY_GOOGLE, // "Hey Google" - emergency trigger
                    // Note: For true emergency keywords like "help", "emergency", "save me"
                    // we need to create custom keywords in Porcupine Console
                ))
                .setSensitivities(floatArrayOf(0.3f, 0.3f, 0.3f)) // Lower sensitivity for easier detection
                .build(this)
            
            Log.d(TAG, "Porcupine keyword detector initialized successfully")
            Log.d(TAG, "Emergency keywords: Alexa, Computer, Hey Google")
            Log.d(TAG, "Porcupine version: ${porcupine?.version}")
            Log.d(TAG, "Frame length: ${porcupine?.frameLength}")
            Log.d(TAG, "Sample rate: ${porcupine?.sampleRate}")
            
        } catch (e: PorcupineException) {
            Log.e(TAG, "Failed to initialize Porcupine: ${e.message}")
            porcupine = null
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error initializing Porcupine: ${e.message}")
            porcupine = null
        }
    }
    
    /**
     * Cleans up Porcupine resources
     */
    private fun cleanupPorcupine() {
        try {
            porcupine?.delete()
            porcupine = null
            Log.d(TAG, "Porcupine cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up Porcupine: ${e.message}")
        }
    }
    
    /**
     * Starts continuous keyword detection
     */
    private fun startKeywordDetection() {
        if (isDetecting) {
            Log.w(TAG, "Keyword detection already running")
            return
        }

        try {
            // Check if Porcupine was initialized successfully
            if (porcupine == null) {
                Log.e(TAG, "Porcupine not initialized. Cannot start detection.")
                eventSink?.error("PORCUPINE_ERROR", "Porcupine initialization failed", null)
                stopSelf()
                return
            }

            // Initialize audio buffer based on Porcupine frame length
            val frameLength = porcupine?.frameLength ?: 512
            audioBuffer = ShortArray(frameLength)
            
            // Calculate buffer size
            val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT) * BUFFER_SIZE_FACTOR
            
            // Create AudioRecord instance
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            ).apply {
                if (state != AudioRecord.STATE_INITIALIZED) {
                    throw IllegalStateException("AudioRecord initialization failed - check microphone permission")
                }
            }            // Start recording
            audioRecord?.startRecording()
            isDetecting = true
            
            // Send success event to Flutter
            eventSink?.success("detection_started")
            
            // Launch audio processing coroutine
            serviceScope.launch {
                processAudioForKeywords()
            }
            
            Log.d(TAG, "Keyword detection started successfully")
            
        } catch (e: SecurityException) {
            Log.e(TAG, "Microphone permission not granted: ${e.message}")
            eventSink?.error("PERMISSION_ERROR", "Microphone permission required", null)
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start keyword detection: ${e.message}")
            eventSink?.error("START_ERROR", "Failed to start detection: ${e.message}", null)
            stopSelf()
        }
    }
    
    /**
     * Stops keyword detection
     */
    private fun stopKeywordDetection() {
        isDetecting = false
        
        try {
            audioRecord?.apply {
                if (state == AudioRecord.STATE_INITIALIZED) {
                    stop()
                }
                release()
            }
            audioRecord = null
            Log.d(TAG, "Keyword detection stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping keyword detection: ${e.message}")
        }
    }
    
    /**
     * Processes audio data for keyword detection
     * Runs in background coroutine
     */
    private suspend fun processAudioForKeywords() = withContext(Dispatchers.IO) {
        Log.d(TAG, "Audio processing started")
        
        val frameLength = porcupine?.frameLength ?: 512
        val frameBuffer = ShortArray(frameLength)
        
        while (isDetecting && audioRecord != null && porcupine != null) {
            try {
                // Read audio data
                val bytesRead = audioRecord?.read(frameBuffer, 0, frameBuffer.size) ?: 0
                
                if (bytesRead > 0) {
                    try {
                        // Process with Porcupine
                        val keywordIndex = porcupine?.process(frameBuffer) ?: -1
                        
                        if (keywordIndex >= 0) {
                            Log.i(TAG, "Keyword detected! Index: $keywordIndex")
                            handleKeywordDetection()
                        }
                        
                    } catch (e: PorcupineException) {
                        Log.e(TAG, "Porcupine processing error: ${e.message}")
                    }
                }
                
                // Small delay to prevent excessive CPU usage
                delay(10)
                
            } catch (e: Exception) {
                Log.e(TAG, "Error processing audio: ${e.message}")
                delay(1000) // Wait before retrying
            }
        }
        
        Log.d(TAG, "Audio processing stopped")
    }
    
    /**
     * Handles keyword detection event
     * Sends notification to Flutter app
     */
    private fun handleKeywordDetection() {
        // Switch to main thread for UI operations
        CoroutineScope(Dispatchers.Main).launch {
            try {
                // Send event to Flutter via EventChannel
                eventSink?.success("help_detected")
                
                // Log the detection
                Log.i(TAG, "Keyword detection event sent to Flutter")
                
                // Update notification to show detection
                val detectionNotification = NotificationCompat.Builder(this@KeywordDetectionService, CHANNEL_ID)
                    .setContentTitle("ResQ Emergency Detection")
                    .setContentText("Emergency keyword detected! Starting recording...")
                    .setSmallIcon(R.drawable.ic_notification)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true)
                    .build()
                    
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID + 1, detectionNotification)
                
            } catch (e: Exception) {
                Log.e(TAG, "Error handling keyword detection: ${e.message}")
            }
        }
    }
}