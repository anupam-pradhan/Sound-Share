import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../../domain/spatial_audio_models.dart';

/// Pixel-perfect 3D Spatial Audio Sound Visualizer.
/// Renders 3D elliptical particle horizon, wireframe soundstage rings,
/// perimeter transducer pods, listener bust avatar, and glowing draggable sound node.
class SpatialSoundVisualizer extends StatefulWidget {
  const SpatialSoundVisualizer({
    super.key,
    required this.position,
    required this.isEnabled,
    required this.onPositionChanged,
    this.isDark = true,
    this.headYaw = 0.0,
    this.isTesting = false,
    this.height = 300,
  });

  final SpatialAudioPosition position;
  final bool isEnabled;
  final ValueChanged<SpatialAudioPosition> onPositionChanged;
  final bool isDark;
  final double headYaw;
  final bool isTesting;
  final double height;

  @override
  State<SpatialSoundVisualizer> createState() => _SpatialSoundVisualizerState();
}

class _SpatialSoundVisualizerState extends State<SpatialSoundVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePan(Offset localOffset, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.40;
    final radiusY = size.height * 0.38;

    double dx = (localOffset.dx - center.dx) / radiusX;
    double dy = (center.dy - localOffset.dy) / radiusY; // Up is +Y (Front)

    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 1.0) {
      dx /= dist;
      dy /= dist;
    }

    widget.onPositionChanged(
      widget.position.copyWith(x: dx.clamp(-1.0, 1.0), y: dy.clamp(-1.0, 1.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, widget.height);
        final center = Offset(size.width / 2, size.height / 2);
        final radiusX = size.width * 0.40;
        final radiusY = size.height * 0.38;

        final nodeOffset = Offset(
          center.dx + widget.position.x * radiusX,
          center.dy - widget.position.y * radiusY,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            setState(() => _isDragging = true);
            AppHaptics.selection();
            _handlePan(details.localPosition, size);
          },
          onPanUpdate: (details) {
            _handlePan(details.localPosition, size);
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            AppHaptics.light();
          },
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Canvas 3D Elliptical Horizon & Field Painter
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: size,
                      painter: _Spatial3DStagePainter(
                        position: widget.position,
                        isEnabled: widget.isEnabled,
                        isDark: widget.isDark,
                        headYaw: widget.headYaw,
                        pulseValue: _pulseController.value,
                        isDragging: _isDragging,
                      ),
                    );
                  },
                ),

                // 2. Speaker/Transducer Pods positioned on the mid soundstage ring
                // FRONT Pod
                _buildSpeakerPod(
                  top: center.dy - radiusY * 0.65 - 14,
                  left: center.dx - 14,
                  icon: Icons.speaker_rounded,
                ),
                // BACK Pod
                _buildSpeakerPod(
                  top: center.dy + radiusY * 0.65 - 14,
                  left: center.dx - 14,
                  icon: Icons.speaker_rounded,
                ),
                // LEFT Pod
                _buildSpeakerPod(
                  top: center.dy - 14,
                  left: center.dx - radiusX * 0.65 - 14,
                  icon: Icons.speaker_group_rounded,
                ),
                // RIGHT Pod
                _buildSpeakerPod(
                  top: center.dy - 14,
                  left: center.dx + radiusX * 0.65 - 14,
                  icon: Icons.speaker_group_rounded,
                ),

                // 3. Direction HUD labels with subtle chevrons at outer perimeter
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'FRONT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: widget.isDark
                              ? const Color(0xFF9E77ED)
                              : const Color(0xFF7A5AF8),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 13,
                        color: widget.isDark
                            ? const Color(0xFF9E77ED)
                            : const Color(0xFF7A5AF8),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 13,
                        color: widget.isDark
                            ? const Color(0xFF757388)
                            : const Color(0xFF9E9AB5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'BACK',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: widget.isDark
                              ? const Color(0xFF757388)
                              : const Color(0xFF9E9AB5),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 13,
                          color: widget.isDark
                              ? const Color(0xFF757388)
                              : const Color(0xFF9E9AB5),
                        ),
                        Text(
                          'LEFT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: widget.isDark
                                ? const Color(0xFF757388)
                                : const Color(0xFF9E9AB5),
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 13,
                          color: widget.isDark
                              ? const Color(0xFF757388)
                              : const Color(0xFF9E9AB5),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 13,
                          color: widget.isDark
                              ? const Color(0xFF757388)
                              : const Color(0xFF9E9AB5),
                        ),
                        Text(
                          'RIGHT',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: widget.isDark
                                ? const Color(0xFF757388)
                                : const Color(0xFF9E9AB5),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 13,
                          color: widget.isDark
                              ? const Color(0xFF757388)
                              : const Color(0xFF9E9AB5),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Interactive Sound Node (Purple Glowing Sphere with concentric waves)
                Positioned(
                  left: nodeOffset.dx - 24,
                  top: nodeOffset.dy - 24,
                  child: _GlowingSoundNode(
                    isEnabled: widget.isEnabled,
                    isDragging: _isDragging,
                    isDark: widget.isDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeakerPod({
    required double top,
    required double left,
    required IconData icon,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF141320).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDark
                ? const Color(0xFF2B2844)
                : const Color(0xFFE4E0F4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.06),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 14,
          color: widget.isDark
              ? const Color(0xFF7D7A94)
              : const Color(0xFF9E9AB5),
        ),
      ),
    );
  }
}

/// Floating Purple Glowing Sound Node with core and expanding rings.
class _GlowingSoundNode extends StatelessWidget {
  const _GlowingSoundNode({
    required this.isEnabled,
    required this.isDragging,
    required this.isDark,
  });

  final bool isEnabled;
  final bool isDragging;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer halo
          if (isEnabled)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9E77ED).withValues(alpha: 0.6),
                    blurRadius: 18,
                    spreadRadius: isDragging ? 5 : 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF53B1FD).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),

          // Central orb
          AnimatedScale(
            scale: isDragging ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isEnabled
                    ? const RadialGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFB4A1FF),
                          Color(0xFF7A5AF8),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      )
                    : RadialGradient(
                        colors: isDark
                            ? [const Color(0xFF55536D), const Color(0xFF262438)]
                            : [const Color(0xFFD6D4E8), const Color(0xFF9E9AB5)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the exact 3D elliptical horizon wireframe dome,
/// particle field, dashed vector ray, and center 3D listener avatar bust.
class _Spatial3DStagePainter extends CustomPainter {
  _Spatial3DStagePainter({
    required this.position,
    required this.isEnabled,
    required this.isDark,
    required this.headYaw,
    required this.pulseValue,
    required this.isDragging,
  });

  final SpatialAudioPosition position;
  final bool isEnabled;
  final bool isDark;
  final double headYaw;
  final double pulseValue;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.40;
    final radiusY = size.height * 0.38;

    // 1. Background atmospheric glow
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          (isEnabled ? const Color(0xFF7A5AF8) : const Color(0xFF333148))
              .withValues(alpha: isDark ? 0.08 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radiusX * 1.2));
    canvas.drawCircle(center, radiusX * 1.2, bgGlow);

    // 2. 3D Elliptical Wireframe Soundstage Rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = isDark
          ? const Color(0xFF242238).withValues(alpha: 0.9)
          : const Color(0xFFE4E0F5);

    // Outer ellipse
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 2.0, height: radiusY * 2.0),
      ringPaint,
    );
    // Mid ellipse
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 1.35, height: radiusY * 1.35),
      ringPaint,
    );
    // Inner center ellipse
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radiusX * 0.70, height: radiusY * 0.70),
      ringPaint,
    );

    // 3. 3D Elliptical Particle Horizon Mesh (Front & Back particle arcs)
    final meshPaint = Paint()..style = PaintingStyle.fill;
    const particleCount = 72;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final px = center.dx + radiusX * math.cos(angle);
      final py = center.dy + radiusY * math.sin(angle);

      // Height modulation creating 3D wave dome effect
      final waveMod = math.sin(angle * 3 + pulseValue * 2 * math.pi) * 3.5;
      final pointY = py + waveMod;

      final isFront = math.sin(angle) > 0;
      final alpha = (0.25 + 0.6 * math.cos(angle).abs()).clamp(0.1, 0.9);

      meshPaint.color = (isFront ? const Color(0xFF7A5AF8) : const Color(0xFF53B1FD))
          .withValues(alpha: isDark ? alpha : alpha * 0.7);

      canvas.drawCircle(Offset(px, pointY), 1.2, meshPaint);
    }

    // 4. Subtle Crosshair Dashed Axes
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = isDark ? const Color(0xFF201E32) : const Color(0xFFEDEAF8);

    canvas.drawLine(
      Offset(center.dx - radiusX, center.dy),
      Offset(center.dx + radiusX, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radiusY),
      Offset(center.dx, center.dy + radiusY),
      axisPaint,
    );

    final nodeOffset = Offset(
      center.dx + position.x * radiusX,
      center.dy - position.y * radiusY,
    );

    // 5. Dashed Connection Vector Ray (Listener ➔ Sound Node)
    if (isEnabled) {
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF9E77ED).withValues(alpha: 0.85);

      // Draw dashed line
      const dashWidth = 4.0;
      const dashGap = 3.5;
      final totalDist = (nodeOffset - center).distance;
      final dx = (nodeOffset.dx - center.dx) / totalDist;
      final dy = (nodeOffset.dy - center.dy) / totalDist;

      double d = 0;
      while (d < totalDist) {
        final start = Offset(center.dx + dx * d, center.dy + dy * d);
        final end = Offset(
          center.dx + dx * math.min(d + dashWidth, totalDist),
          center.dy + dy * math.min(d + dashWidth, totalDist),
        );
        canvas.drawLine(start, end, rayPaint);
        d += dashWidth + dashGap;
      }

      // Expanding concentric sound ripples around active node
      for (int i = 0; i < 3; i++) {
        final prog = (pulseValue + i / 3.0) % 1.0;
        final waveR = 14.0 + prog * 36.0;
        final alpha = (1.0 - prog).clamp(0.0, 1.0) * 0.45;

        final wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * (1.0 - prog * 0.5)
          ..color = const Color(0xFFB4A1FF).withValues(alpha: alpha);

        canvas.drawCircle(nodeOffset, waveR, wavePaint);
      }
    }

    // 6. Center 3D Listener Avatar Bust ("YOU")
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headYaw);

    // Subtle ambient glow beneath head
    final headGlow = Paint()
      ..color = const Color(0xFF7A5AF8).withValues(alpha: isDark ? 0.25 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, 18, headGlow);

    // Listener Shoulder Bust (gradient arc)
    final shoulderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9E77ED), Color(0xFF6941C6)],
      ).createShader(const Rect.fromLTWH(-16, 2, 32, 14))
      ..style = PaintingStyle.fill;

    final shoulderPath = Path()
      ..moveTo(-15, 14)
      ..quadraticBezierTo(-12, 4, -6, 2)
      ..lineTo(6, 2)
      ..quadraticBezierTo(12, 4, 15, 14)
      ..close();
    canvas.drawPath(shoulderPath, shoulderPaint);

    // Listener Head (glossy sphere)
    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [
          Color(0xFFE9D7FE),
          Color(0xFFB4A1FF),
          Color(0xFF7A5AF8),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(const Rect.fromLTWH(-8, -13, 16, 16));

    canvas.drawOval(
      const Rect.fromLTWH(-7.5, -13, 15, 16),
      headPaint,
    );

    // Head border
    final headBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawOval(
      const Rect.fromLTWH(-7.5, -13, 15, 16),
      headBorder,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_Spatial3DStagePainter old) =>
      old.position != position ||
      old.isEnabled != isEnabled ||
      old.isDark != isDark ||
      old.headYaw != headYaw ||
      old.pulseValue != pulseValue ||
      old.isDragging != isDragging;
}
