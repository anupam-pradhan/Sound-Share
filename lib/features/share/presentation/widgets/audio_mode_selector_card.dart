import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';

/// Compact segmented control for choosing how audio is shared.
class AudioModeSelectorCard extends ConsumerWidget {
  const AudioModeSelectorCard({super.key});

  static const _modes = [
    (
      mode: AudioSharingMode.samsungDualAudio,
      label: 'Bluetooth',
      icon: Icons.headphones_rounded,
    ),
    (
      mode: AudioSharingMode.universalPeerShare,
      label: 'Wi-Fi',
      icon: Icons.wifi_rounded,
    ),
    (
      mode: AudioSharingMode.auracastBroadcast,
      label: 'LE Audio',
      icon: Icons.podcasts_rounded,
    ),
  ];

  static String _description(AudioSharingMode mode) => switch (mode) {
        AudioSharingMode.samsungDualAudio =>
          'Two headphones on this phone using its built-in dual audio, or Bluetooth + wired.',
        AudioSharingMode.universalPeerShare =>
          'Friends on your Wi-Fi or hotspot listen on their own phone. No app needed.',
        AudioSharingMode.auracastBroadcast =>
          'Android Audio Sharing for LE Audio earbuds (Android 15+).',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(activeSharingModeProvider);
    final recommended =
        ref.watch(audioSharingCapabilityProvider).valueOrNull?.recommendedMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _modes.indexWhere((m) => m.mode == activeMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Sharing mode'),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17152A) : const Color(0xFFEFEDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Surface.borderColor(context)),
          ),
          child: Stack(
            children: [
              // Sliding selection indicator
              Positioned.fill(
                child: AnimatedAlign(
                  duration:
                      Motion.reduced(context) ? Duration.zero : Motion.medium,
                  curve: Motion.emphasized,
                  alignment: Alignment(-1 + selectedIndex.clamp(0, 2) * 1.0, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _modes.length,
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E2A4A)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple
                                .withValues(alpha: isDark ? 0.0 : 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    for (final m in _modes)
                      Expanded(
                        child: _Segment(
                          label: m.label,
                          icon: m.icon,
                          selected: m.mode == activeMode,
                          onTap: () {
                            AppHaptics.selection();
                            ref
                                .read(activeSharingModeProvider.notifier)
                                .setMode(m.mode);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedSwitcher(
            duration: Motion.medium,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Row(
              key: ValueKey(activeMode),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _description(activeMode),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
                if (activeMode == recommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Best for this phone',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.purple : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label sharing mode',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: Motion.fast,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
