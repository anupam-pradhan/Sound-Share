import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';

import 'dual_headphone_setup_sheet.dart';
import 'peer_sharing_qr_dialog.dart';

/// The focal card of the Share screen: where audio is going and what to do next.
class ShareHeroCard extends StatelessWidget {
  const ShareHeroCard({
    super.key,
    required this.connectedDevices,
    required this.sharingState,
    required this.sharingDuration,
    required this.btEnabled,
    required this.activeMode,
    required this.peersCount,
  });

  final List<BluetoothDeviceModel> connectedDevices;
  final AudioSharingState sharingState;
  final Duration sharingDuration;
  final bool btEnabled;
  final AudioSharingMode activeMode;
  final int peersCount;

  bool get _isSharing => sharingState == AudioSharingState.sharing;
  bool get _isWifi => activeMode == AudioSharingMode.universalPeerShare;
  int get _count => connectedDevices.length;
  int get _playing => connectedDevices.where((d) => d.isAudioActive).length;
  bool get _oneAtATime => _count >= 2 && _playing < 2;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  String get _statusText {
    if (_isSharing) return 'Live • ${_formatDuration(sharingDuration)}';
    if (!btEnabled && !_isWifi) return 'Bluetooth off';
    return switch (sharingState) {
      AudioSharingState.starting => 'Starting…',
      AudioSharingState.stopping => 'Stopping…',
      AudioSharingState.error => 'Something went wrong',
      _ => 'Ready',
    };
  }

  String get _title {
    if (!btEnabled && !_isWifi) return 'Bluetooth is off';
    if (_isSharing && _isWifi) {
      return peersCount == 0
          ? 'Waiting for friends'
          : '$peersCount ${peersCount == 1 ? 'friend' : 'friends'} listening';
    }
    if (_isSharing) return 'Sharing your audio';
    if (_isWifi) return 'Share with friends';
    if (_count == 0) {
      return _isWifi ? 'Share with friends' : 'Connect headphones';
    }
    return '$_count ${_count == 1 ? 'headphone' : 'headphones'} connected';
  }

  String get _subtitle {
    if (!btEnabled && !_isWifi) return 'Turn it on to find your headphones.';
    if (_isWifi) {
      return _isSharing
          ? 'Friends on your Wi-Fi can join from the invite link.'
          : 'Friends on your Wi-Fi listen on their own phone.';
    }
    if (_oneAtATime) return 'Only one can play at a time on this phone.';
    if (_count == 0) return 'Connect a Bluetooth or wired headphone to start.';
    if (_count == 1) return 'Add a second headphone to listen together.';
    return _isSharing
        ? 'Playing on all your headphones.'
        : 'Tap Share Audio to start listening together.';
  }

  /// Contextual follow-up link under the subtitle, if any.
  ({String label, void Function(BuildContext) onTap})? get _link {
    if (!btEnabled && !_isWifi) return null;
    if (_isWifi) {
      return (label: 'Invite friends', onTap: PeerSharingQrDialog.show);
    }
    if (_oneAtATime) {
      return (label: 'See options', onTap: DualHeadphoneSetupSheet.show);
    }
    if (_count < 2) {
      return (label: 'Add headphone', onTap: DualHeadphoneSetupSheet.show);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Soft light orbs give the gradient depth
            const Positioned(right: -40, top: -50, child: _Orb(size: 180)),
            const Positioned(left: -30, bottom: -60, child: _Orb(size: 140)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(text: _statusText, live: _isSharing),
                  const SizedBox(height: 22),
                  _SignalRow(
                    devices: connectedDevices,
                    isSharing: _isSharing,
                    isWifi: _isWifi,
                    peersCount: peersCount,
                  ),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: Text(
                      _title,
                      key: ValueKey(_title),
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                  if (!btEnabled && !_isWifi) ...[
                    const SizedBox(height: 16),
                    _HeroButton(
                      label: 'Turn on Bluetooth',
                      onTap: () async {
                        AppHaptics.light();
                        try {
                          await FlutterBluePlus.turnOn();
                        } on Exception catch (_) {}
                      },
                    ),
                  ] else if (link != null) ...[
                    const SizedBox(height: 14),
                    _HeroButton(
                      label: link.label,
                      onTap: () {
                        AppHaptics.light();
                        link.onTap(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.live});
  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: live ? const Color(0xFF5BF5B0) : Colors.white,
              boxShadow: live
                  ? [const BoxShadow(color: Color(0xFF5BF5B0), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.purple),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone → signal → headphones (or friends for Wi-Fi share).
class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.devices,
    required this.isSharing,
    required this.isWifi,
    required this.peersCount,
  });

  final List<BluetoothDeviceModel> devices;
  final bool isSharing;
  final bool isWifi;
  final int peersCount;

  static const _maxShown = 2;

  @override
  Widget build(BuildContext context) {
    final shown = devices.take(_maxShown).toList();
    final extra = devices.length - shown.length;

    final List<Widget> targets = isWifi
        ? [
            _Node(
              icon: Icons.groups_rounded,
              dimmed: peersCount == 0,
              badge: peersCount > 0 ? '$peersCount' : null,
            ),
          ]
        : shown.isEmpty
            ? [const _Node(icon: Icons.headphones_rounded, dimmed: true)]
            : [
                for (final d in shown)
                  _Node(
                    icon: Icons.headphones_rounded,
                    dimmed: !d.isAudioActive,
                  ),
                if (extra > 0) _Node(label: '+$extra'),
              ];

    return Row(
      children: [
        const _Node(icon: Icons.smartphone_rounded, emphasized: true),
        const SizedBox(width: 10),
        Expanded(child: _SignalLine(active: isSharing)),
        const SizedBox(width: 10),
        for (int i = 0; i < targets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          targets[i],
        ],
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    this.icon,
    this.label,
    this.dimmed = false,
    this.emphasized = false,
    this.badge,
  });

  final IconData? icon;
  final String? label;
  final bool dimmed;
  final bool emphasized;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final size = emphasized ? 54.0 : 48.0;
    return AnimatedOpacity(
      opacity: dimmed ? 0.45 : 1,
      duration: Motion.medium,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: emphasized ? 0.95 : 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(
                    icon,
                    size: emphasized ? 26 : 22,
                    color: emphasized ? AppColors.purple : Colors.white,
                  )
                : Text(
                    label ?? '',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BF5B0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B3D2A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dotted connector whose dots flow toward the headphones while sharing.
class _SignalLine extends StatefulWidget {
  const _SignalLine({required this.active});
  final bool active;

  @override
  State<_SignalLine> createState() => _SignalLineState();
}

class _SignalLineState extends State<_SignalLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  void _sync() {
    final shouldRun = widget.active && !Motion.reduced(context);
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SignalLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _DotsPainter(
            phase: _controller.value,
            active: widget.active,
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.phase, required this.active});
  final double phase;
  final bool active;

  static const _spacing = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final y = size.height / 2;
    final offset = phase * _spacing;
    for (double x = offset; x < size.width; x += _spacing) {
      // Brighter toward the centre of the line for a soft beam effect
      final t = (x / size.width - 0.5).abs() * 2;
      final alpha = active ? (0.95 - 0.5 * t) : 0.35;
      paint.color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), active ? 2.4 : 2, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.phase != phase || old.active != active;
}
