import 'package:flutter/material.dart';
import '../models/recording.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'dart:async';
import 'dart:io';

enum RecordingStatus { idle, monitoring, recording, processing, emergency, error }

class RecordingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AudioService _audioService = AudioService();
  
  RecordingStatus _status = RecordingStatus.idle;
  List<Recording> _recordings = [];
  List<Recording> _emergencyRecordings = [];
  Recording? _latestRecording;
  String? _error;
  
  // Recording state
  bool _isMonitoring = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  double _audioLevel = 0.0;
  
  // Emergency detection
  bool _emergencyDetected = false;
  Recording? _emergencyRecording;

  // Getters
  RecordingStatus get status => _status;
  List<Recording> get recordings => _recordings;
  List<Recording> get emergencyRecordings => _emergencyRecordings;
  Recording? get latestRecording => _latestRecording;
  String? get error => _error;
  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;
  int get recordingDuration => _recordingDuration;
  double get audioLevel => _audioLevel;
  bool get emergencyDetected => _emergencyDetected;
  Recording? get emergencyRecording => _emergencyRecording;

  String get statusText {
    switch (_status) {
      case RecordingStatus.idle:
        return 'Click Start Monitoring to begin';
      case RecordingStatus.monitoring:
        return 'Monitoring active - Ready to record';
      case RecordingStatus.recording:
        return 'Recording in progress...';
      case RecordingStatus.processing:
        return 'Processing audio...';
      case RecordingStatus.emergency:
        return 'Emergency detected! Alert sent.';
      case RecordingStatus.error:
        return 'Error occurred';
    }
  }

  Future<void> startMonitoring() async {
    try {
      _setError(null);
      
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        final granted = await _audioService.requestPermissions();
        if (!granted) {
          throw Exception('Microphone permission is required');
        }
      }
      
      _isMonitoring = true;
      _setStatus(RecordingStatus.monitoring);
      
      // Start audio level monitoring (simulation)
      _startAudioLevelMonitoring();
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(RecordingStatus.error);
    }
  }

  Future<void> stopMonitoring() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      
      _isMonitoring = false;
      _stopAudioLevelMonitoring();
      _setStatus(RecordingStatus.idle);
      
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> startRecording() async {
    if (!_isMonitoring || _isRecording) return;
    
    try {
      _setError(null);
      final filePath = await _audioService.startRecording();
      
      if (filePath != null) {
        _isRecording = true;
        _recordingDuration = 0;
        _setStatus(RecordingStatus.recording);
        
        // Start recording timer
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _recordingDuration++;
          notifyListeners();
          
          // Auto-stop after 30 seconds
          if (_recordingDuration >= 30) {
            stopRecording();
          }
        });
      }
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(RecordingStatus.error);
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final filePath = await _audioService.stopRecording();
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      if (filePath != null) {
        _setStatus(RecordingStatus.processing);
        await _processRecording(filePath);
      } else {
        _setStatus(_isMonitoring ? RecordingStatus.monitoring : RecordingStatus.idle);
      }
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(RecordingStatus.error);
    }
  }

  Future<void> _processRecording(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      final response = await _apiService.uploadRecording(filePath, fileName);
      final recording = Recording.fromJson(response['recording']);
      
      _latestRecording = recording;
      _recordings.insert(0, recording);
      
      // Check for emergency
      if (recording.isEmergency) {
        _emergencyDetected = true;
        _emergencyRecording = recording;
        _emergencyRecordings.insert(0, recording);
        _setStatus(RecordingStatus.emergency);
        
        // Reset emergency status after 3 seconds
        Timer(const Duration(seconds: 3), () {
          _emergencyDetected = false;
          _emergencyRecording = null;
          _setStatus(_isMonitoring ? RecordingStatus.monitoring : RecordingStatus.idle);
        });
      } else {
        _setStatus(_isMonitoring ? RecordingStatus.monitoring : RecordingStatus.idle);
      }
      
      // Clean up the local file
      if (await file.exists()) {
        await file.delete();
      }
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(RecordingStatus.error);
    }
  }

  void _startAudioLevelMonitoring() {
    // Simulate audio level changes
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      // Simulate random audio levels
      _audioLevel = (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
      notifyListeners();
    });
  }

  void _stopAudioLevelMonitoring() {
    _audioLevel = 0.0;
    notifyListeners();
  }

  Future<void> fetchRecordings({int page = 1, int limit = 10}) async {
    try {
      _setError(null);
      final response = await _apiService.getRecordings(page: page, limit: limit);
      
      final recordingList = (response['recordings'] as List)
          .map((json) => Recording.fromJson(json))
          .toList();
      
      if (page == 1) {
        _recordings = recordingList;
      } else {
        _recordings.addAll(recordingList);
      }
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> fetchEmergencyRecordings() async {
    try {
      _setError(null);
      final response = await _apiService.getEmergencyRecordings();
      
      _emergencyRecordings = (response['recordings'] as List)
          .map((json) => Recording.fromJson(json))
          .toList();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> deleteRecording(String recordingId) async {
    try {
      _setError(null);
      await _apiService.deleteRecording(recordingId);
      
      _recordings.removeWhere((r) => r.id == recordingId);
      _emergencyRecordings.removeWhere((r) => r.id == recordingId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearEmergencyAlert() {
    _emergencyDetected = false;
    _emergencyRecording = null;
    notifyListeners();
  }

  void _setStatus(RecordingStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}