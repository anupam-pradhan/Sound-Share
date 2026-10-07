import 'dart:async';

import 'package:flutter/material.dart';

/// Shared motion tokens so every screen moves with the same rhythm.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);

  /// Delay between consecutive items in a staggered entrance.
  static const stagger = Duration(milliseconds: 55);

  /// Cap so long lists don't make the user wait for the last item.
  static const maxStaggerSteps = 8;

  static const emphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const decelerate = Curves.easeOutCubic;

  /// Honour the system "Remove animations" accessibility setting.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Fades and lifts its child into place once, after a stagger delay based on [index].
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.duration = Motion.slow,
  });

  final Widget child;

  /// Position in a staggered group; 0 plays immediately.
  final int index;

  /// Vertical travel in logical pixels.
  final double offset;
  final Duration duration;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Motion.emphasized);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, Motion.maxStaggerSteps);
    _delay = Timer(Motion.stagger * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: Transform.scale(scale: 0.98 + 0.02 * t, child: child),
          ),
        );
      },
    );
  }
}

/// Smoothly expands/collapses and cross-fades content that appears conditionally.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context) ? Duration.zero : Motion.medium;
    return AnimatedSize(
      duration: duration,
      curve: Motion.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.decelerate,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: visible
            ? KeyedSubtree(key: const ValueKey(true), child: child)
            : const SizedBox(key: ValueKey(false), width: double.infinity),
      ),
    );
  }
}

/// Gives any tappable surface a tactile press-down scale.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Listener(
      onPointerDown: enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Motion.reduced(context) ? Duration.zero : Motion.fast,
        curve: Motion.decelerate,
        child: widget.child,
      ),
    );
  }
}

/// Fade-through transition between bottom-nav tabs that keeps each tab's state alive.
class FadeThroughBranchContainer extends StatelessWidget {
  const FadeThroughBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.reduced(context) ? Duration.zero : Motion.medium;
    return Stack(
      children: [
        for (int i = 0; i < children.length; i++)
          _Branch(
            isActive: i == currentIndex,
            duration: duration,
            child: children[i],
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({
    required this.isActive,
    required this.duration,
    required this.child,
  });

  final bool isActive;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isActive,
        child: AnimatedOpacity(
          opacity: isActive ? 1 : 0,
          duration: duration,
          curve: isActive ? Motion.decelerate : Curves.easeInCubic,
          child: AnimatedScale(
            scale: isActive ? 1 : 0.985,
            duration: duration,
            curve: Motion.emphasized,
            // Pause the hidden tab's own animations, but not this fade itself
            child: TickerMode(
              enabled: isActive,
              child: ExcludeSemantics(excluding: !isActive, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
