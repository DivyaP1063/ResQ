package com.example.flutter_frontend

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_frontend.services.KeywordDetectionService

/**
 * MainActivity with keyword detection integration
 * Handles communication between Flutter and Android native keyword detection service
 */
class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.example.flutter_frontend/keyword_detection"
    private val EVENT_CHANNEL = "com.example.flutter_frontend/keyword_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Check if we were launched due to emergency detection
        checkForEmergencyIntent()
        
        // Set up MethodChannel for Flutter -> Android communication
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startKeywordDetection" -> {
                    startKeywordDetection(result)
                }
                "stopKeywordDetection" -> {
                    stopKeywordDetection(result)
                }
                "isKeywordDetectionRunning" -> {
                    checkKeywordDetectionStatus(result)
                }
                "saveTokenForEmergency" -> {
                    saveTokenForEmergency(call.arguments as? String, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up EventChannel for Android -> Flutter communication
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // Set the event sink for the keyword detection service
                KeywordDetectionService.eventSink = events
                android.util.Log.d("MainActivity", "EventChannel listener attached, eventSink set")
                
                // Send a test event to confirm connection
                events?.success("event_channel_connected")
            }
            
            override fun onCancel(arguments: Any?) {
                // Clear the event sink
                KeywordDetectionService.eventSink = null
                android.util.Log.d("MainActivity", "EventChannel listener cancelled, eventSink cleared")
            }
        })
    }
    
    /**
     * Starts the keyword detection service
     */
    private fun startKeywordDetection(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, KeywordDetectionService::class.java)
            ContextCompat.startForegroundService(this, serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("START_ERROR", "Failed to start keyword detection: ${e.message}", null)
        }
    }
    
    /**
     * Stops the keyword detection service
     */
    private fun stopKeywordDetection(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, KeywordDetectionService::class.java)
            stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop keyword detection: ${e.message}", null)
        }
    }
    
    /**
     * Checks if keyword detection service is running
     */
    private fun checkKeywordDetectionStatus(result: MethodChannel.Result) {
        try {
            // This is a simple implementation
            // In a production app, you might want to check the actual service status
            result.success(true) // Placeholder - always return true for now
        } catch (e: Exception) {
            result.error("STATUS_ERROR", "Failed to check service status: ${e.message}", null)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Clean up channels
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        KeywordDetectionService.eventSink = null
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        checkForEmergencyIntent()
    }
    
    /**
     * Saves authentication token for emergency uploads
     */
    private fun saveTokenForEmergency(token: String?, result: MethodChannel.Result) {
        try {
            if (token != null) {
                val sharedPref = getSharedPreferences("EmergencyAuth", Context.MODE_PRIVATE)
                with(sharedPref.edit()) {
                    putString("auth_token", token)
                    apply()
                }
                android.util.Log.d("MainActivity", "Token saved for emergency uploads")
                result.success(true)
            } else {
                result.error("NO_TOKEN", "Token is null", null)
            }
        } catch (e: Exception) {
            result.error("SAVE_ERROR", "Failed to save token: ${e.message}", null)
        }
    }

    private fun checkForEmergencyIntent() {
        val emergencyDetected = intent?.getBooleanExtra("emergency_detected", false) ?: false
        val emergencyConfirmed = intent?.getBooleanExtra("emergency_confirmed", false) ?: false
        
        if (emergencyDetected || emergencyConfirmed) {
            android.util.Log.d("MainActivity", "Emergency intent detected: detected=$emergencyDetected, confirmed=$emergencyConfirmed")
            
            // Send emergency event to Flutter when the channel is ready
            methodChannel?.invokeMethod("onEmergencyDetectedFromBackground", mapOf(
                "emergencyDetected" to emergencyDetected,
                "emergencyConfirmed" to emergencyConfirmed
            ))
        }
    }
}