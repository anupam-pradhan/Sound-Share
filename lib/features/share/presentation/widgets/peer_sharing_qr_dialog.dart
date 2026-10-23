import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/analytics/analytics_service.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';

/// Bottom sheet friends scan to listen along in their browser.
class PeerSharingQrDialog extends ConsumerWidget {
  const PeerSharingQrDialog({super.key});

  static void show(BuildContext context) {
    AnalyticsService.instance.invitePeersOpened();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PeerSharingQrDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(broadcastUrlProvider).valueOrNull;
    final peers = ref.watch(connectedPeersCountProvider).valueOrNull ?? 0;
    final sharingState = ref.watch(audioSharingStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFFA09EAE) : AppColors.textSecondary;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141322) : AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3E3B59) : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            _LiveBadge(url: url, peers: peers),
            const SizedBox(height: 12),
            Text(
              'Scan to listen along',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Friends on your Wi-Fi or hotspot point their camera here — '
              'no app needed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: url != null
                  ? _QrCard(key: ValueKey(url), url: url)
                  : _StartCard(
                      isStarting: sharingState == AudioSharingState.starting,
                      onStart: () {
                        AppHaptics.medium();
                        ref
                            .read(audioSharingStateProvider.notifier)
                            .startSharing();
                      },
                    ),
            ),
            if (url != null) ...[
              const SizedBox(height: 14),
              _LinkRow(url: url, isDark: isDark),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    AppHaptics.medium();
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Listen along with me on SoundShare 🎧\n'
                            '1. Join my Wi-Fi / hotspot\n'
                            '2. Open $url',
                      ),
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Send link'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.url, required this.peers});
  final String? url;
  final int peers;

  @override
  Widget build(BuildContext context) {
    final live = url != null;
    final color = live ? const Color(0xFF12B76A) : AppColors.purple;
    final label = !live
        ? 'NOT SHARING YET'
        : peers == 0
            ? 'LIVE • WAITING FOR FRIENDS'
            : 'LIVE • $peers ${peers == 1 ? 'FRIEND' : 'FRIENDS'} LISTENING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({super.key, required this.url});
  final String url;

  static const _ink = Color(0xFF17132C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // QR codes scan best dark-on-light, in either app theme
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: QrImageView(
        data: url,
        size: 220,
        padding: EdgeInsets.zero,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        semanticsLabel: 'QR code for $url',
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: _ink),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: _ink,
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.isStarting, required this.onStart});
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded,
              size: 72, color: AppColors.purpleLight),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isStarting ? null : onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isStarting ? 'Starting…' : 'Start sharing'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Android will ask to share your screen audio — choose “Entire screen”.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url, required this.isDark});
  final String url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF1D1B30) : const Color(0xFFF4F3FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppHaptics.light();
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link copied'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.link_rounded,
                  size: 18, color: AppColors.purpleLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  url,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purpleLight,
                  ),
                ),
              ),
              Icon(Icons.copy_rounded,
                  size: 16,
                  color: isDark ? Colors.white54 : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
