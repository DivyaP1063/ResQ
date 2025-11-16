package com.example.flutter_frontend.services

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.asRequestBody
import org.json.JSONObject

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
    
    // Emergency recording when app is closed
    private var emergencyRecorder: MediaRecorder? = null
    private var isEmergencyRecording = false
    private val okHttpClient = OkHttpClient()
    
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
        
        // Stop emergency recording if active
        if (isEmergencyRecording) {
            try {
                emergencyRecorder?.apply {
                    stop()
                    release()
                }
                emergencyRecorder = null
                isEmergencyRecording = false
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping emergency recording: ${e.message}")
            }
        }
        
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

        // Check for required permissions
        if (!hasRequiredPermissions()) {
            Log.e(TAG, "Missing required permissions for keyword detection")
            eventSink?.error("PERMISSION_ERROR", "Required permissions not granted", null)
            stopSelf()
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
     * Check if the service has all required permissions
     */
    private fun hasRequiredPermissions(): Boolean {
        val recordAudioPermission = ContextCompat.checkSelfPermission(
            this, 
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        val foregroundServicePermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            ContextCompat.checkSelfPermission(
                this, 
                Manifest.permission.FOREGROUND_SERVICE_MICROPHONE
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Not required for older versions
        }
        
        return recordAudioPermission && foregroundServicePermission
    }
    
    /**
     * Handles keyword detection event
     * If app is open: sends event to Flutter
     * If app is closed: starts emergency recording and brings app to foreground
     */
    private fun handleKeywordDetection() {
        // Switch to main thread for UI operations
        CoroutineScope(Dispatchers.Main).launch {
            try {
                Log.i(TAG, "Emergency keyword detected!")
                
                if (eventSink != null) {
                    // App is open - send event to Flutter
                    Log.d(TAG, "App is open, sending event to Flutter")
                    eventSink?.success("help_detected")
                    
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
                } else {
                    // App is closed - handle emergency directly
                    Log.d(TAG, "App is closed, starting emergency recording")
                    handleEmergencyWhenAppClosed()
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error handling keyword detection: ${e.message}")
            }
        }
    }
    
    /**
     * Handles emergency detection when app is closed
     * Starts recording, brings app to foreground, and uploads to backend
     */
    private fun handleEmergencyWhenAppClosed() {
        try {
            // Start emergency recording
            startEmergencyRecording()
            
            // Bring app to foreground
            bringAppToForeground()
            
            // Show urgent notification
            showEmergencyNotification()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling emergency when app closed: ${e.message}")
        }
    }
    
    /**
     * Starts emergency recording directly from service
     */
    private fun startEmergencyRecording() {
        if (isEmergencyRecording) {
            Log.w(TAG, "Emergency recording already in progress")
            return
        }
        
        try {
            Log.d(TAG, "Starting emergency recording from service")
            
            // Create recording file
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val fileName = "emergency_recording_$timestamp.m4a"
            val recordingFile = File(filesDir, fileName)
            
            // Initialize MediaRecorder
            emergencyRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(recordingFile.absolutePath)
                prepare()
                start()
            }
            
            isEmergencyRecording = true
            
            // Schedule automatic stop after 30 seconds
            serviceScope.launch {
                delay(30000) // 30 seconds
                stopEmergencyRecording(recordingFile)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start emergency recording: ${e.message}")
            emergencyRecorder = null
            isEmergencyRecording = false
        }
    }
    
    /**
     * Stops emergency recording and uploads to backend
     */
    private fun stopEmergencyRecording(recordingFile: File) {
        if (!isEmergencyRecording) return
        
        try {
            Log.d(TAG, "Stopping emergency recording")
            
            emergencyRecorder?.apply {
                stop()
                release()
            }
            emergencyRecorder = null
            isEmergencyRecording = false
            
            // Upload to backend
            serviceScope.launch {
                uploadEmergencyRecording(recordingFile)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop emergency recording: ${e.message}")
            emergencyRecorder = null
            isEmergencyRecording = false
        }
    }
    
    /**
     * Uploads emergency recording to backend
     */
    private suspend fun uploadEmergencyRecording(recordingFile: File) = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Uploading emergency recording: ${recordingFile.name}")
            
            if (!recordingFile.exists()) {
                Log.e(TAG, "Recording file not found: ${recordingFile.absolutePath}")
                return@withContext
            }
            
            // Get auth token from SharedPreferences (try multiple possible locations)
            var token: String? = null
            
            // First, try the emergency auth storage (most reliable)
            try {
                val emergencyPrefs = getSharedPreferences("EmergencyAuth", Context.MODE_PRIVATE)
                token = emergencyPrefs.getString("auth_token", null)
                if (token != null) {
                    Log.d(TAG, "Found token in EmergencyAuth preferences")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reading EmergencyAuth preferences: ${e.message}")
            }
            
            // If not found, try Flutter SharedPreferences directly
            if (token == null) {
                try {
                    val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    
                    // Try the exact key we saw in the logs: flutter.resq_token
                    token = flutterPrefs.getString("flutter.resq_token", null)
                    
                    if (token != null && token.trim().isNotEmpty()) {
                        Log.d(TAG, "Found token in flutter.resq_token")
                    } else {
                        Log.d(TAG, "flutter.resq_token is null or empty")
                        token = null
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading Flutter SharedPreferences: ${e.message}")
                }
            }
            
            // Final fallback - try standard SharedPreferences
            if (token == null) {
                try {
                    val standardPrefs = getSharedPreferences(packageName + "_preferences", Context.MODE_PRIVATE)
                    token = standardPrefs.getString("resq_token", null)
                    if (token != null) {
                        Log.d(TAG, "Found token in standard preferences")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error reading standard SharedPreferences: ${e.message}")
                }
            }
            
            if (token == null) {
                Log.w(TAG, "No auth token found in any SharedPreferences, uploading as anonymous emergency")
                Log.w(TAG, "This will likely result in a 401 Unauthorized error")
            } else {
                Log.d(TAG, "Found auth token for emergency upload (length: ${token.length})")
                Log.d(TAG, "Token starts with: ${token.take(10)}...")
            }
            
            // Create multipart request
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart(
                    "audio", 
                    recordingFile.name,
                    recordingFile.asRequestBody("audio/mp4".toMediaTypeOrNull()) // Changed from audio/m4a to audio/mp4
                )
                .addFormDataPart("isEmergency", "true")
                .addFormDataPart("source", "background_keyword_detection")
                .build()
            
            val request = Request.Builder()
                .url("http://10.88.25.141:5000/api/recordings/upload") // Match Flutter config
                .post(requestBody)
                .apply {
                    if (token != null && token.trim().isNotEmpty()) {
                        header("Authorization", "Bearer $token")
                        Log.d(TAG, "Added Authorization header with Bearer token")
                    } else {
                        Log.w(TAG, "No valid token available, request will be unauthenticated")
                    }
                }
                .build()
            
            Log.d(TAG, "Sending upload request to backend...")
            val response = okHttpClient.newCall(request).execute()
            
            Log.d(TAG, "Upload response: ${response.code} ${response.message}")
            
            if (response.isSuccessful) {
                Log.i(TAG, "Emergency recording uploaded successfully")
                
                // Parse response to check if emergency was detected
                val responseBody = response.body?.string()
                if (responseBody != null) {
                    val jsonResponse = JSONObject(responseBody)
                    val recording = jsonResponse.getJSONObject("recording")
                    val isEmergency = recording.getBoolean("isEmergency")
                    
                    Log.i(TAG, "Backend analysis - Emergency detected: $isEmergency")
                    
                    if (isEmergency) {
                        showEmergencyConfirmedNotification()
                    }
                }
                
                // Clean up the file after successful upload
                recordingFile.delete()
                
            } else {
                Log.e(TAG, "Failed to upload emergency recording: ${response.code} ${response.message}")
                
                // Log response body for debugging
                val errorBody = response.body?.string()
                if (errorBody != null) {
                    Log.e(TAG, "Error response body: $errorBody")
                } else {
                    Log.e(TAG, "No error response body")
                }
                
                // If it's a 401 error, the issue is definitely authentication
                if (response.code == 401) {
                    Log.e(TAG, "Authentication failed - token is missing, invalid, or expired")
                    if (token == null) {
                        Log.e(TAG, "Root cause: No token found in any SharedPreferences")
                    } else {
                        Log.e(TAG, "Root cause: Token exists but server rejected it")
                        Log.e(TAG, "Token used: ${token.take(20)}...")
                    }
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error uploading emergency recording: ${e.message}")
        }
    }
    
    /**
     * Brings the app to foreground
     */
    private fun bringAppToForeground() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("emergency_detected", true)
            }
            startActivity(intent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bring app to foreground: ${e.message}")
        }
    }
    
    /**
     * Shows urgent emergency notification
     */
    private fun showEmergencyNotification() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("emergency_detected", true)
            }
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("🚨 EMERGENCY DETECTED")
                .setContentText("Emergency keyword detected! Recording started automatically.")
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setVibrate(longArrayOf(0, 500, 200, 500))
                .build()
                
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID + 2, notification)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show emergency notification: ${e.message}")
        }
    }
    
    /**
     * Shows notification when emergency is confirmed by backend
     */
    private fun showEmergencyConfirmedNotification() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                putExtra("emergency_confirmed", true)
            }
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("🆘 EMERGENCY CONFIRMED")
                .setContentText("Emergency alert has been sent to your contacts!")
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setVibrate(longArrayOf(0, 1000, 500, 1000))
                .build()
                
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID + 3, notification)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show emergency confirmed notification: ${e.message}")
        }
    }
}