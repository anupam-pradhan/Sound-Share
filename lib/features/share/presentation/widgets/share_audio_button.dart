import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';

/// Full-width gradient Share Audio button with all state transitions.
class ShareAudioButton extends StatefulWidget {
  const ShareAudioButton({
    super.key,
    required this.state,
    required this.onShare,
    required this.onStop,
    this.sharingDuration,
  });

  final AudioSharingState state;
  final VoidCallback onShare;
  final VoidCallback onStop;
  final Duration? sharingDuration;

  @override
  State<ShareAudioButton> createState() => _ShareAudioButtonState();
}

class _ShareAudioButtonState extends State<ShareAudioButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowController;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.state == AudioSharingState.sharing) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShareAudioButton old) {
    super.didUpdateWidget(old);
    if (widget.state == AudioSharingState.sharing &&
        !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (widget.state != AudioSharingState.sharing) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  bool get _isEnabled =>
      widget.state == AudioSharingState.ready ||
      widget.state == AudioSharingState.sharing;

  bool get _isSharing => widget.state == AudioSharingState.sharing;
  bool get _isLoading =>
      widget.state == AudioSharingState.starting ||
      widget.state == AudioSharingState.stopping;

  void _onTap() {
    if (!_isEnabled && !_isSharing) return;
    HapticFeedback.mediumImpact();
    if (_isSharing) {
      widget.onStop();
    } else {
      widget.onShare();
    }
  }

  String get _label {
    switch (widget.state) {
      case AudioSharingState.starting:
        return 'Starting...';
      case AudioSharingState.sharing:
        return 'Sharing Audio';
      case AudioSharingState.stopping:
        return 'Stopping...';
      case AudioSharingState.unavailable:
        return 'Connect a Device to Share';
      default:
        return 'Share Audio';
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final active = _isEnabled || _isSharing;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _pressed = false);
              _onTap();
            }
          : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (_, __) {
            return Container(
              height: 56,
              decoration: active
                  ? AppGradients.primaryButton(radius: 18).copyWith(
                      boxShadow: _isSharing
                          ? [
                              BoxShadow(
                                color: AppColors.purple.withValues(
                                    alpha: 0.25 + 0.25 * _glow.value),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : AppGradients.primaryButton(radius: 18).boxShadow,
                    )
                  : AppGradients.disabledButtonOf(context, radius: 18),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      _ButtonIcon(
                        isSharing: _isSharing,
                        isEnabled: active,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _label,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: active ? Colors.white : AppColors.disabledText,
                      ),
                    ),
                    if (_isSharing &&
                        widget.sharingDuration != null &&
                        widget.sharingDuration!.inSeconds > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(widget.sharingDuration!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({required this.isSharing, required this.isEnabled});
  final bool isSharing;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _ShareIconPainter(
        isSharing: isSharing,
        color: isEnabled ? Colors.white : AppColors.disabledText,
      ),
    );
  }
}

class _ShareIconPainter extends CustomPainter {
  _ShareIconPainter({required this.isSharing, required this.color});
  final bool isSharing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    if (isSharing) {
      // Stop/pause icon
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.25, h * 0.7),
          const Radius.circular(2),
        ),
        paint..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.6, h * 0.15, w * 0.25, h * 0.7),
          const Radius.circular(2),
        ),
        paint,
      );
    } else {
      // Share/wireless icon
      // Center dot
      canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.08,
          paint..style = PaintingStyle.fill);

      // Inner arc
      paint.style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5), width: w * 0.5, height: h * 0.5),
        -2.4,
        1.7,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5), width: w * 0.5, height: h * 0.5),
        0.7 + 0.24,
        1.7,
        false,
        paint,
      );

      // Outer arc
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.85,
            height: h * 0.85),
        -2.7,
        2.0,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.85,
            height: h * 0.85),
        0.7,
        2.0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShareIconPainter old) =>
      old.isSharing != isSharing || old.color != color;
}
