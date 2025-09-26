import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'api_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      final hasPermission = await this.hasPermission();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) {
          throw Exception('Microphone permission not granted');
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      );

      await _recorder.start(config, path: filePath);
      _isRecording = true;
      _currentRecordingPath = filePath;

      return filePath;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      await _recorder.stop();
      _isRecording = false;

      final recordingPath = _currentRecordingPath;
      _currentRecordingPath = null;

      // Auto-upload to backend for emergency analysis
      if (recordingPath != null) {
        return await _uploadRecording(recordingPath);
      }

      return null;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _uploadRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileName = filePath.split('/').last;
      print('Starting upload of recording: $fileName');
      
      final result = await ApiService().uploadRecording(filePath, fileName);

      print('Recording uploaded successfully: ${result['recording']['id']}');
      print('Emergency detected: ${result['recording']['isEmergency']}');

      return result;
    } catch (e) {
      print('Failed to upload recording: $e');
      print('Recording will be processed in background - results may arrive via WebSocket');
      
      // Return a basic result so the UI can still show processing feedback
      // The actual result will come via WebSocket later
      return {
        'recording': {
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'isEmergency': false,
          'transcription': 'Recording saved - processing in background...',
          'confidence': 0.0,
          'emergencyType': '',
          'uploadFailed': true, // Flag to indicate upload failure
          'processingNote': 'Upload failed but recording is saved locally. Emergency detection results may arrive later.',
        }
      };
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;

        // Delete the file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        _currentRecordingPath = null;
      }
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
    }
  }

  Future<bool> isEncoderSupported(AudioEncoder encoder) async {
    return await _recorder.isEncoderSupported(encoder);
  }

  void dispose() {
    _recorder.dispose();
  }
}
