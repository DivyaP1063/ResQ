import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for managing keyword detection functionality
/// Communicates with Android native code via MethodChannel and EventChannel
class KeywordDetectionService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.flutter_frontend/keyword_detection');

  static const EventChannel _eventChannel =
      EventChannel('com.example.flutter_frontend/keyword_events');

  static Stream<String>? _keywordStream;

  /// Stream of keyword detection events
  /// Emits 'help_detected' when emergency keywords are detected
  static Stream<String> get keywordDetectionStream {
    if (_keywordStream == null) {
      debugPrint('KeywordDetectionService: Creating new event stream');
      _keywordStream = _eventChannel.receiveBroadcastStream().map((event) {
        debugPrint('KeywordDetectionService: Raw event received: $event');
        return event.toString();
      });
    }
    return _keywordStream!;
  }

  /// Starts the keyword detection service
  /// Returns true if service started successfully
  static Future<bool> startKeywordDetection() async {
    try {
      final bool result =
          await _methodChannel.invokeMethod('startKeywordDetection');
      debugPrint('Keyword detection started: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error starting keyword detection: ${e.message}');
      return false;
    }
  }

  /// Stops the keyword detection service
  /// Returns true if service stopped successfully
  static Future<bool> stopKeywordDetection() async {
    try {
      final bool result =
          await _methodChannel.invokeMethod('stopKeywordDetection');
      debugPrint('Keyword detection stopped: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error stopping keyword detection: ${e.message}');
      return false;
    }
  }

  /// Checks if keyword detection service is running
  /// Returns true if service is currently active
  static Future<bool> isKeywordDetectionRunning() async {
    try {
      final bool result =
          await _methodChannel.invokeMethod('isKeywordDetectionRunning');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking keyword detection status: ${e.message}');
      return false;
    }
  }
}
