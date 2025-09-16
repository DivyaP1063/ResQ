import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final AnimationController animationController;

  const AudioVisualizer({
    super.key,
    required this.isRecording,
    required this.animationController,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 100),
          painter: WaveformPainter(
            animationValue: widget.animationController.value,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;

  WaveformPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    final barWidth = size.width / 50;

    for (int i = 0; i < 50; i++) {
      final x = i * barWidth;
      final normalizedI = i / 50.0;
      final phase = animationValue * 2 * math.pi + normalizedI * 4 * math.pi;
      
      // Create different wave patterns for different bars
      final height1 = math.sin(phase) * 20;
      final height2 = math.cos(phase * 1.5) * 15;
      final height3 = math.sin(phase * 0.7) * 10;
      
      final totalHeight = (height1 + height2 + height3) * 
          (0.5 + 0.5 * math.sin(animationValue * math.pi + normalizedI * math.pi));

      if (i == 0) {
        path.moveTo(x, centerY + totalHeight);
      } else {
        path.lineTo(x, centerY + totalHeight);
      }
    }

    canvas.drawPath(path, paint);

    // Draw mirror image below
    final mirrorPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final mirrorPath = Path();
    for (int i = 0; i < 50; i++) {
      final x = i * barWidth;
      final normalizedI = i / 50.0;
      final phase = animationValue * 2 * math.pi + normalizedI * 4 * math.pi;
      
      final height1 = math.sin(phase) * 20;
      final height2 = math.cos(phase * 1.5) * 15;
      final height3 = math.sin(phase * 0.7) * 10;
      
      final totalHeight = (height1 + height2 + height3) * 
          (0.5 + 0.5 * math.sin(animationValue * math.pi + normalizedI * math.pi));

      if (i == 0) {
        mirrorPath.moveTo(x, centerY - totalHeight);
      } else {
        mirrorPath.lineTo(x, centerY - totalHeight);
      }
    }

    canvas.drawPath(mirrorPath, mirrorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}