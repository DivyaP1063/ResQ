import 'package:flutter/material.dart';
import '../utils/theme.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onToggleRecording;
  final AnimationController pulseController;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.onToggleRecording,
    required this.pulseController,
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
              final scale = isRecording ? 1.0 + (pulseController.value * 0.1) : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: onToggleRecording,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording ? Colors.red : AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? Colors.red : AppTheme.primaryColor)
                              .withOpacity(0.3),
                          blurRadius: isRecording ? 20 : 15,
                          spreadRadius: isRecording ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
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
            isRecording ? 'Tap to Stop' : 'Tap to Record',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
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