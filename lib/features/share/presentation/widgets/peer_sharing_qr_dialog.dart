import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';

class PeerSharingQrDialog extends ConsumerWidget {
  const PeerSharingQrDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PeerSharingQrDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastUrl = ref.watch(broadcastUrlProvider).valueOrNull;
    final peersCount = ref.watch(connectedPeersCountProvider).valueOrNull ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141322) : AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2B45) : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3E3B59) : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title & Status ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF12B76A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF12B76A).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF32D583),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      peersCount > 0
                          ? '$peersCount FRIEND${peersCount > 1 ? 'S' : ''} LISTENING'
                          : 'LIVE BROADCAST READY',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF32D583),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Share with a Friend',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Anyone on the same Wi-Fi or Hotspot can listen along through their own headphones without installing any app!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? const Color(0xFFA09EAE) : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // ── Visual Link Box ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D1B30) : const Color(0xFFF4F3FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF343050) : const Color(0xFFE2E0F5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: AppColors.purpleLight,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        broadcastUrl ?? 'Generating local network stream...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: AppColors.purpleLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy link',
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                      onPressed: broadcastUrl != null
                          ? () {
                              AppHaptics.light();
                              Clipboard.setData(ClipboardData(text: broadcastUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stream link copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Step-by-step Instructions ──────────────────
          _buildInstructionStep(
            number: '1',
            title: 'Connect Devices',
            desc: 'Ensure your friend is connected to your Hotspot or same Wi-Fi.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            number: '2',
            title: 'Open Stream Link',
            desc: 'Friend opens the link in Chrome/Safari or SoundShare.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            number: '3',
            title: 'Plug In & Enjoy',
            desc: 'Friend connects their headphones to their phone and hears live audio!',
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // ── Share Button ───────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: broadcastUrl != null
                  ? () {
                      AppHaptics.medium();
                      Share.share(
                        'Join my SoundShare live audio stream: $broadcastUrl\n(Connect to my Hotspot or Wi-Fi to listen in sync!)',
                      );
                    }
                  : null,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text(
                'Share Link via WhatsApp / Apps',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.purpleLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
