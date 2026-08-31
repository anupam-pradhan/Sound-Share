import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../features/bluetooth/domain/bluetooth_device_model.dart';
import 'bluetooth_device_icon.dart';

/// Animated audio flow panel showing source → waveform → destination.
/// When [isSharing] is true, particles animate along the connection path.
class AudioFlowAnimation extends StatefulWidget {
  const AudioFlowAnimation({
    super.key,
    required this.isSharing,
    this.connectedDevice,
    this.height = 100,
  });

  final bool isSharing;
  final BluetoothDeviceModel? connectedDevice;
  final double height;

  @override
  State<AudioFlowAnimation> createState() => _AudioFlowAnimationState();
}

class _AudioFlowAnimationState extends State<AudioFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isSharing) _controller.repeat();
  }

  @override
  void didUpdateWidget(AudioFlowAnimation old) {
    super.didUpdateWidget(old);
    if (widget.isSharing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSharing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
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
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Source device (your earbuds)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BluetoothDeviceIcon(
                type: BluetoothDeviceType.earbuds,
                size: 28,
                isConnected: true,
              ),
              const SizedBox(height: 4),
              Text(
                'Your device',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Animated connection line
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FlowLinePainter(
                      progress: _controller.value,
                      isSharing: widget.isSharing,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // Destination device
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: widget.connectedDevice != null
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: widget.isSharing
                            ? [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.35),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      )
                    : null,
                child: BluetoothDeviceIcon(
                  type: widget.connectedDevice?.type ??
                      BluetoothDeviceType.headphones,
                  size: 28,
                  isConnected: widget.connectedDevice != null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.connectedDevice != null
                    ? _shortenName(widget.connectedDevice!.name)
                    : 'No device',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortenName(String name) {
    if (name.length <= 12) return name;
    return '${name.substring(0, 11)}…';
  }
}

class _FlowLinePainter extends CustomPainter {
  _FlowLinePainter({required this.progress, required this.isSharing});

  final double progress;
  final bool isSharing;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final lineWidth = size.width;

    // Base dashed line
    final dashPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw dashes
    const dashWidth = 6.0;
    const dashGap = 4.0;
    double x = 0;
    while (x < lineWidth) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(math.min(x + dashWidth, lineWidth), centerY),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }

    if (!isSharing) return;

    // Animated particles
    const particleCount = 4;
    for (int i = 0; i < particleCount; i++) {
      final offset = (progress + i / particleCount) % 1.0;
      final particleX = offset * lineWidth;

      // Trailing particle
      final opacity = (math.sin(offset * math.pi)).clamp(0.0, 1.0);
      final particlePaint = Paint()
        ..color = AppColors.purple.withOpacity(opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particleX, centerY), 3.0, particlePaint);

      // Glow
      final glowPaint = Paint()
        ..color = AppColors.blue.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(particleX, centerY), 6.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_FlowLinePainter old) =>
      old.progress != progress || old.isSharing != isSharing;
}
