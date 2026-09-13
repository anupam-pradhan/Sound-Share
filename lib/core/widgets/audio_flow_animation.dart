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
    this.connectedDevices,
    this.height = 100,
  });

  final bool isSharing;
  final BluetoothDeviceModel? connectedDevice;
  final List<BluetoothDeviceModel>? connectedDevices;
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
          // Source device (this phone)
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BluetoothDeviceIcon(
                type: BluetoothDeviceType.phone,
                size: 28,
                isConnected: true,
              ),
              SizedBox(height: 4),
              Text(
                'This phone',
                style: TextStyle(
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
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return CustomPaint(
                    painter: _FlowLinePainter(
                      progress: _controller.value,
                      isSharing: widget.isSharing,
                      isDark: isDark,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

          // Destination devices (Supports Dual Headphone visualization)
          _buildDestination(),
        ],
      ),
    );
  }

  Widget _buildDestination() {
    final devices = widget.connectedDevices ??
        (widget.connectedDevice != null ? [widget.connectedDevice!] : []);

    if (devices.isEmpty) {
      return _buildDeviceBadge(null, 'No headphone');
    }

    if (devices.length == 1) {
      return _buildDeviceBadge(devices.first, _shortenName(devices.first.name));
    }

    // 2 or more headphones (Dual Headphone mode)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeviceBadge(devices[0], _shortenName(devices[0].name), badge: 'HP 1'),
        const SizedBox(width: 8),
        _buildDeviceBadge(devices[1], _shortenName(devices[1].name), badge: 'HP 2'),
      ],
    );
  }

  Widget _buildDeviceBadge(BluetoothDeviceModel? dev, String label, {String? badge}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: dev != null
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: widget.isSharing
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    )
                  : null,
              child: BluetoothDeviceIcon(
                type: dev?.type ?? BluetoothDeviceType.headphones,
                size: 26,
                isConnected: dev != null,
              ),
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _shortenName(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 9)}…';
  }
}

class _FlowLinePainter extends CustomPainter {
  _FlowLinePainter({
    required this.progress,
    required this.isSharing,
    required this.isDark,
  });

  final double progress;
  final bool isSharing;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final lineWidth = size.width;

    // Base dashed line
    final dashPaint = Paint()
      ..color = isDark ? const Color(0xFF333148) : AppColors.cardBorder
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
        ..color = AppColors.purple.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particleX, centerY), 3.0, particlePaint);

      // Glow
      final glowPaint = Paint()
        ..color = AppColors.blue.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(particleX, centerY), 6.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_FlowLinePainter old) =>
      old.progress != progress ||
      old.isSharing != isSharing ||
      old.isDark != isDark;
}
