import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Expanding ring pulse — used on connect success.
class PulseIndicator extends StatefulWidget {
  const PulseIndicator({
    super.key,
    this.color = AppColors.success,
    this.size = 52,
    this.duration = const Duration(milliseconds: 800),
    this.child,
  });

  final Color color;
  final double size;
  final Duration duration;
  final Widget? child;

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 0.6, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: _opacity.value),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// Simple scanning animation — rotating arc around a Bluetooth icon.
class ScanningAnimation extends StatefulWidget {
  const ScanningAnimation({
    super.key,
    this.size = 20,
    this.color = AppColors.purple,
  });

  final double size;
  final Color color;

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CircularProgressIndicator(
          value: null,
          strokeWidth: 2,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Animated status badge (green dot) that fades in on first show.
class AnimatedStatusBadge extends StatefulWidget {
  const AnimatedStatusBadge({
    super.key,
    required this.isActive,
    this.activeColor = AppColors.success,
    this.inactiveColor = AppColors.textMuted,
    this.size = 8,
  });

  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  @override
  State<AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedStatusBadge old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: widget.isActive ? _pulse.value : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive ? widget.activeColor : widget.inactiveColor,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
