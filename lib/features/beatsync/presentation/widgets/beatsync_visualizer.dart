import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import '../../domain/beat_event.dart';
import '../../domain/beatsync_providers.dart';

/// Synchronized dynamic audio waveform and beat visualizer.
/// Reacts to real-time [BeatEvent]s emitted by the native audio analysis engine.
class BeatSyncVisualizer extends ConsumerStatefulWidget {
  const BeatSyncVisualizer({
    super.key,
    this.height = 140,
    this.isActive = false,
  });

  final double height;
  final bool isActive;

  @override
  ConsumerState<BeatSyncVisualizer> createState() => _BeatSyncVisualizerState();
}

class _BeatSyncVisualizerState extends ConsumerState<BeatSyncVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _beatController;
  late Animation<double> _pulseScale;
  late Animation<double> _glowOpacity;

  StreamSubscription<BeatEvent>? _beatSub;
  BeatType _lastBeatType = BeatType.kick;
  double _lastStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _beatController, curve: Curves.easeOutCubic),
    );

    _glowOpacity = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _beatController, curve: Curves.easeOutQuad),
    );

    _listenToBeatEvents();
  }

  void _listenToBeatEvents() {
    final service = ref.read(beatSyncServiceProvider);
    _beatSub = service.beatEvents.listen((event) {
      if (!mounted) return;
      _onBeatReceived(event);
    });
  }

  void _onBeatReceived(BeatEvent event) {
    if (MediaQuery.of(context).disableAnimations) return;

    setState(() {
      _lastBeatType = event.type;
      _lastStrength = event.strength;
    });

    _beatController.forward(from: 0.0).then((_) {
      if (mounted) {
        _beatController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _beatSub?.cancel();
    _beatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _beatController,
      builder: (context, _) {
        final scale = disableAnim ? 1.0 : (widget.isActive ? _pulseScale.value : 1.0);
        final glow = disableAnim ? 0.2 : (widget.isActive ? _glowOpacity.value : 0.15);

        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purple.withValues(alpha: 0.05 + 0.08 * glow),
                AppColors.blue.withValues(alpha: 0.04 + 0.06 * glow),
              ],
            ),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.purple.withValues(alpha: 0.3 + 0.3 * glow)
                  : AppColors.cardBorder,
              width: widget.isActive ? 1.5 : 1,
            ),
            boxShadow: [
              if (widget.isActive)
                BoxShadow(
                  color: (_lastBeatType == BeatType.drop
                          ? AppColors.blue
                          : AppColors.purple)
                      .withValues(alpha: 0.2 * glow),
                  blurRadius: 28 * scale,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              painter: _VisualizerPainter(
                beatProgress: _beatController.value,
                strength: _lastStrength,
                beatType: _lastBeatType,
                isActive: widget.isActive,
                primaryColor: widget.isActive ? AppColors.purple : AppColors.textMuted,
                accentColor: widget.isActive ? AppColors.blue : AppColors.disabled,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.beatProgress,
    required this.strength,
    required this.beatType,
    required this.isActive,
    required this.primaryColor,
    required this.accentColor,
  });

  final double beatProgress;
  final double strength;
  final BeatType beatType;
  final bool isActive;
  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h * 0.5;

    // Background center reference line
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(16, centerY), Offset(w - 16, centerY), linePaint);

    // Number of visualizer bars
    const barCount = 28;
    final totalSpacing = w - 40;
    final barWidth = (totalSpacing / barCount) * 0.55;
    final gap = (totalSpacing / barCount) * 0.45;

    final barPaint = Paint()..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = 20 + i * (barWidth + gap) + barWidth / 2;

      // Base symmetric height pattern (bell curve)
      final normalizedPos = (i - barCount / 2).abs() / (barCount / 2);
      final envelope = 1.0 - math.pow(normalizedPos, 1.4);

      // Reactive pulse height according to beat type
      double pulseMultiplier = 1.0;
      if (isActive && beatProgress > 0) {
        final decay = 1.0 - beatProgress;
        if (beatType == BeatType.drop) {
          pulseMultiplier = 1.0 + (strength * 2.2 * decay);
        } else if (beatType == BeatType.kick || beatType == BeatType.strongBeat) {
          pulseMultiplier = 1.0 + (strength * 1.6 * decay);
        } else {
          pulseMultiplier = 1.0 + (strength * 0.9 * decay);
        }
      }

      final barHeight = ((h * 0.38 * envelope * pulseMultiplier) + (isActive ? 6 : 4))
          .clamp(4.0, h * 0.85);

      // Gradient color interpolation
      final colorFraction = i / barCount;
      final barColor = Color.lerp(primaryColor, accentColor, colorFraction)!
          .withValues(alpha: isActive ? (0.65 + 0.35 * (1.0 - beatProgress)) : 0.35);

      barPaint.color = barColor;
      barPaint.strokeWidth = barWidth;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        barPaint,
      );
    }

    // Drop expanding wave effect
    if (isActive && beatType == BeatType.drop && beatProgress > 0) {
      final wavePaint = Paint()
        ..color = accentColor.withValues(alpha: (1.0 - beatProgress) * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final radius = (size.width * 0.45) * beatProgress;
      canvas.drawCircle(Offset(w * 0.5, centerY), radius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) =>
      old.beatProgress != beatProgress ||
      old.isActive != isActive ||
      old.strength != strength ||
      old.beatType != beatType;
}
