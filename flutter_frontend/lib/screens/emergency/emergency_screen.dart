import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/theme.dart';
import '../../widgets/audio_visualizer.dart';
import '../../widgets/recording_controls.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  bool _isRecording = false;
  bool _isProcessing = false; // Add processing state
  final AudioService _audioService = AudioService();
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize WebSocket for emergency alerts
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    // Note: You'll need to get the current user ID from your auth provider
    // _wsService.connect(currentUserId);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    // Prevent multiple calls when processing
    if (_isProcessing) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _audioService.startRecording();
      setState(() => _isRecording = true);

      _pulseController.repeat();
      _waveController.repeat();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Set processing state and update UI
      setState(() {
        _isProcessing = true;
      });

      // Show processing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Processing recording...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 10), // Longer duration for processing
          ),
        );
      }

      final result = await _audioService.stopRecording();
      setState(() => _isRecording = false);

      _pulseController.stop();
      _waveController.stop();

      if (result != null && mounted) {
        // Check if upload failed but we got a placeholder result
        final uploadFailed = result['recording']?['uploadFailed'] ?? false;

        if (uploadFailed) {
          // Show upload failure message but keep processing
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Upload slow - Processing in background. Results will appear in Home.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          // Normal processing - check if emergency was detected
          final isEmergency = result['recording']?['isEmergency'] ?? false;
          final transcription = result['recording']?['transcription'] ?? '';
          // Safely convert confidence to double to avoid type errors
          final confidenceValue = result['recording']?['confidence'];
          final confidence =
              (confidenceValue is num) ? confidenceValue.toDouble() : 0.0;
          final emergencyType = result['recording']?['emergencyType'] ?? '';

          if (isEmergency) {
            // Send WebSocket alert for real-time notifications
            _wsService.sendEmergencyAlert(transcription, confidence);

            // Show emergency alert
            _showEmergencyAlert(transcription, confidence, emergencyType);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recording processed - No emergency detected'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset processing state
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showEmergencyAlert(
      String transcription, double confidence, String emergencyType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red, width: 3),
          ),
          title: Row(
            children: [
              Expanded(child: Icon(Icons.warning, color: Colors.red, size: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'EMERGENCY DETECTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detected Speech:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  '"$transcription"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency Type:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(emergencyType.toUpperCase(),
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Confidence:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Emergency alert has been automatically sent to monitoring system.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Acknowledge',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Emergency Detection',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.orange
                            : _isRecording
                                ? Colors.red
                                : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isProcessing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            Icon(
                              _isRecording
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color:
                                  _isRecording ? Colors.white : Colors.white70,
                              size: 16,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _isProcessing
                                ? 'PROCESSING'
                                : _isRecording
                                    ? 'RECORDING'
                                    : 'READY',
                            style: TextStyle(
                              color: _isProcessing || _isRecording
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Recording Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Status Text
                      Text(
                        _isProcessing
                            ? 'Processing recording...'
                            : _isRecording
                                ? 'Listening for emergencies...'
                                : 'Tap to start emergency detection',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      // Audio Visualizer
                      Expanded(
                        child: Center(
                            child: _isRecording
                                ? AudioVisualizer(
                                    isRecording: _isRecording,
                                    animationController: _waveController,
                                  )
                                : null
                            // : Icon(
                            //     Icons.mic_outlined,
                            //     size: 120,
                            //     color: Colors.grey.shade400,
                            //   ),
                            ),
                      ),

                      // Recording Controls
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 40, right: 40, bottom: 40),
                        child: RecordingControls(
                          isRecording: _isRecording,
                          onToggleRecording: _toggleRecording,
                          pulseController: _pulseController,
                          isProcessing: _isProcessing, // Pass processing state
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Instructions
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap the record button to start listening. Our AI will analyze the audio in real-time and automatically detect emergency situations like calls for help, accidents, or distress signals.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
