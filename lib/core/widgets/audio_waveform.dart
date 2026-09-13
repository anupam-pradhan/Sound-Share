import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Animated audio waveform visualization.
/// Adjusts animation intensity based on [isActive] and [isSharing].
class AudioWaveform extends StatefulWidget {
  const AudioWaveform({
    super.key,
    this.isActive = false,
    this.isSharing = false,
    this.barCount = 24,
    this.color = AppColors.purple,
    this.height = 40,
    this.width = double.infinity,
  });

  final bool isActive;
  final bool isSharing;
  final int barCount;
  final Color color;
  final double height;
  final double width;

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              phase: _animation.value,
              isActive: widget.isActive,
              isSharing: widget.isSharing,
              barCount: widget.barCount,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.phase,
    required this.isActive,
    required this.isSharing,
    required this.barCount,
    required this.color,
  });

  final double phase;
  final bool isActive;
  final bool isSharing;
  final int barCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (barCount * 1.8);
    final spacing = size.width / barCount;
    final centerY = size.height / 2;

    final baseAmplitude = isSharing
        ? size.height * 0.42
        : isActive
            ? size.height * 0.32
            : size.height * 0.08;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      final relPos = i / barCount;

      // Multi-frequency wave for organic feel
      double amplitude = math.sin(phase + relPos * 2 * math.pi) * 0.5 +
          math.sin(phase * 1.5 + relPos * 3 * math.pi) * 0.3 +
          math.sin(phase * 0.7 + relPos * math.pi) * 0.2;

      amplitude = (amplitude.abs()) * baseAmplitude + baseAmplitude * 0.15;

      final barHeight = amplitude.clamp(2.0, size.height * 0.9);

      // Gradient opacity — center bars more opaque
      final opacity = 0.4 + 0.6 * math.sin(relPos * math.pi).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.phase != phase ||
      old.isActive != isActive ||
      old.isSharing != isSharing;
}
