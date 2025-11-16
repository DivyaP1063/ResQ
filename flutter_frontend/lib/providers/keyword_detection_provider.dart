import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/keyword_detection_service.dart';
import '../services/audio_service.dart';

/// Provider for managing keyword detection state and integration with recording
class KeywordDetectionProvider extends ChangeNotifier {
  bool _isDetectionActive = false;
  bool _isListening = false;
  StreamSubscription<String>? _keywordSubscription;
  final AudioService _audioService = AudioService();

  /// Callback for when emergency is detected
  Function()? onEmergencyDetected;

  /// Whether keyword detection is currently active
  bool get isDetectionActive => _isDetectionActive;

  /// Whether the service is listening for keyword events
  bool get isListening => _isListening;

  KeywordDetectionProvider() {
    // Set up callback for emergency detection from background
    KeywordDetectionService.setEmergencyFromBackgroundCallback(
        _handleEmergencyFromBackground);
  }

  /// Handles emergency detected when app was closed
  void _handleEmergencyFromBackground(Map<String, dynamic> data) {
    debugPrint('Emergency detected from background service: $data');

    final emergencyDetected = data['emergencyDetected'] as bool? ?? false;
    final emergencyConfirmed = data['emergencyConfirmed'] as bool? ?? false;

    if (emergencyDetected || emergencyConfirmed) {
      // If emergency was detected in background, the recording is already done
      // Just notify the app that emergency was handled
      debugPrint('🚨 Emergency was already handled by background service!');

      if (emergencyConfirmed) {
        debugPrint('✅ Emergency confirmed by backend - alerts were sent!');
      }

      // Trigger emergency callback if set
      onEmergencyDetected?.call();

      // Notify listeners to update UI
      notifyListeners();
    }
  }

  /// Starts keyword detection and sets up event listening
  Future<bool> startDetection() async {
    try {
      debugPrint('Starting keyword detection...');

      // Start listening for events BEFORE starting the service
      _startListening();

      // Wait a moment for the EventChannel to be established
      await Future.delayed(const Duration(milliseconds: 500));

      // Start the native keyword detection service
      final success = await KeywordDetectionService.startKeywordDetection();

      if (success) {
        _isDetectionActive = true;
        notifyListeners();
        debugPrint('Keyword detection started successfully');
        return true;
      } else {
        debugPrint('Failed to start keyword detection');
        _stopListening();
        return false;
      }
    } catch (e) {
      debugPrint('Error starting keyword detection: $e');
      _stopListening();
      return false;
    }
  }

  /// Stops keyword detection and event listening
  Future<bool> stopDetection() async {
    try {
      // Stop listening for events first
      _stopListening();

      // Stop the native keyword detection service
      final success = await KeywordDetectionService.stopKeywordDetection();

      _isDetectionActive = false;
      notifyListeners();

      if (success) {
        debugPrint('Keyword detection stopped successfully');
        return true;
      } else {
        debugPrint('Failed to stop keyword detection');
        return false;
      }
    } catch (e) {
      debugPrint('Error stopping keyword detection: $e');
      return false;
    }
  }

  /// Checks the current status of keyword detection
  Future<bool> checkDetectionStatus() async {
    try {
      final isRunning =
          await KeywordDetectionService.isKeywordDetectionRunning();
      _isDetectionActive = isRunning;
      notifyListeners();
      return isRunning;
    } catch (e) {
      debugPrint('Error checking detection status: $e');
      return false;
    }
  }

  /// Starts listening for keyword detection events
  void _startListening() {
    if (_isListening) return;

    debugPrint('Starting to listen for keyword detection events...');
    _isListening = true;

    _keywordSubscription =
        KeywordDetectionService.keywordDetectionStream.listen(
      (event) {
        debugPrint('Keyword detection event received: $event');
        if (event == 'help_detected') {
          debugPrint(
              '🚨 EMERGENCY KEYWORD DETECTED! Starting automatic recording...');
          _handleKeywordDetection();
        } else if (event == 'detection_started') {
          debugPrint('Detection service started successfully');
        } else if (event == 'event_channel_connected') {
          debugPrint('EventChannel connection confirmed');
        }
      },
      onError: (error) {
        debugPrint('Error in keyword detection stream: $error');
        _isListening = false;
        _isDetectionActive = false;
        notifyListeners();
      },
      onDone: () {
        debugPrint('Keyword detection stream closed');
        _isListening = false;
        notifyListeners();
      },
    );

    debugPrint(
        'Keyword detection stream subscription created, _isListening: $_isListening');
    notifyListeners();
  }

  /// Stops listening for keyword detection events
  void _stopListening() {
    _keywordSubscription?.cancel();
    _keywordSubscription = null;
    _isListening = false;
  }

  /// Handles keyword detection event by starting emergency recording
  Future<void> _handleKeywordDetection() async {
    try {
      debugPrint(
          '🚨 EMERGENCY KEYWORD DETECTED! Starting automatic recording...');

      // Start emergency recording automatically
      final recording = await _audioService.startRecording();

      if (recording != null) {
        debugPrint('✅ Emergency recording started successfully: $recording');

        // Optional: Stop recording after 30 seconds automatically
        Future.delayed(const Duration(seconds: 30), () async {
          try {
            final result = await _audioService.stopRecording();
            debugPrint(
                '🎙️ Emergency recording completed and uploaded: $result');
          } catch (e) {
            debugPrint('❌ Error stopping emergency recording: $e');
          }
        });
      } else {
        debugPrint('❌ Failed to start emergency recording');
      }

      // You could also trigger other emergency actions here:
      // - Send push notification
      // - Update UI to show emergency state
      // - Send location to emergency contacts
      // - Trigger email notifications

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling keyword detection: $e');
    }
  }

  /// Toggles keyword detection on/off
  Future<bool> toggleDetection() async {
    if (_isDetectionActive) {
      return await stopDetection();
    } else {
      return await startDetection();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
