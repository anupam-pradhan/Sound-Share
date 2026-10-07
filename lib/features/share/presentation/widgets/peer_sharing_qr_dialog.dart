import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/app_sheet.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';

/// Invite friends on the same Wi-Fi/hotspot to listen from their own phone.
class PeerSharingQrDialog extends ConsumerWidget {
  const PeerSharingQrDialog({super.key});

  static void show(BuildContext context) {
    AppSheet.show<void>(context, (_) => const PeerSharingQrDialog());
  }

  static const _steps = [
    'Your friend joins your Wi-Fi or hotspot.',
    'They scan the code or open the link in their browser.',
    'They tap Listen and hear your audio on their own headphones.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(broadcastUrlProvider).valueOrNull;
    final peers = ref.watch(connectedPeersCountProvider).valueOrNull ?? 0;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ready = url != null;

    return AppSheet(
      title: 'Invite friends',
      subtitle: ready
          ? (peers > 0
              ? '$peers ${peers == 1 ? 'friend' : 'friends'} listening'
              : 'Same Wi-Fi or hotspot')
          : 'Same Wi-Fi or hotspot',
      icon: Icons.wifi_rounded,
      footer: PrimaryButton(
        label: 'Share link',
        icon: Icons.ios_share_rounded,
        onPressed: ready
            ? () {
                AppHaptics.medium();
                Share.share(
                  'Listen along with me on SoundShare: $url\n'
                  '(Join my Wi-Fi or hotspot first.)',
                );
              }
            : null,
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: Motion.medium,
            child: ready
                ? _QrCard(key: const ValueKey('qr'), url: url)
                : const _NotReadyCard(key: ValueKey('waiting')),
          ),
          if (ready) ...[
            const SizedBox(height: 14),
            _LinkRow(url: url),
          ],
          const SizedBox(height: 22),
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _steps[i],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: onSurface.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Surface.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: url,
        size: 180,
        padding: EdgeInsets.zero,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: Color(0xFF1A1A2E),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}

class _NotReadyCard extends StatelessWidget {
  const _NotReadyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 28,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start sharing to get your link',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose Wi-Fi mode and tap Share Audio. Your QR code appears here.',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodySmall.copyWith(fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 18, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppColors.purple,
            onPressed: () {
              AppHaptics.light();
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
