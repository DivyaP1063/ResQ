import 'package:flutter/material.dart';
import '../utils/theme.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onToggleRecording;
  final AnimationController pulseController;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.onToggleRecording,
    required this.pulseController,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Main Record Button
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale =
                  isRecording ? 1.0 + (pulseController.value * 0.1) : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: isProcessing
                      ? null
                      : onToggleRecording, // Disable when processing
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isProcessing
                          ? Colors.grey
                          : isRecording
                              ? Colors.red
                              : AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (isProcessing
                                  ? Colors.grey
                                  : isRecording
                                      ? Colors.red
                                      : AppTheme.primaryColor)
                              .withOpacity(0.3),
                          blurRadius: isRecording ? 20 : 15,
                          spreadRadius: isRecording ? 5 : 0,
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Record Button Label
          Text(
            isProcessing
                ? 'Processing...'
                : isRecording
                    ? 'Tap to Stop'
                    : 'Tap to Record',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isProcessing ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
          ),

          if (isRecording) ...[
            const SizedBox(height: 12),
            Text(
              'AI is analyzing audio...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
