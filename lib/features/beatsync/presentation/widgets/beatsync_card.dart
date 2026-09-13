import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../../domain/beat_event.dart';
import '../../domain/beatsync_providers.dart';

/// Compact card displayed on the main Share Screen representing BeatSync.
class BeatSyncCard extends ConsumerWidget {
  const BeatSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(beatSyncSettingsProvider);
    final status = ref.watch(beatSyncStatusProvider);
    final isEnabled = settings.enabled;
    final isActivelyVibrating = status == BeatSyncStatus.active;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled
              ? AppColors.purple.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
          width: isEnabled ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEnabled
                ? AppColors.purple.withValues(alpha: 0.12)
                : (isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.cardShadow),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            AppHaptics.light();
            context.push('/beatsync');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Header + Custom Switch
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isEnabled
                            ? const LinearGradient(
                                colors: [AppColors.purple, AppColors.blue],
                              )
                            : null,
                        color: isEnabled ? null : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.vibration_rounded,
                        size: 20,
                        color: isEnabled ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('BeatSync', style: AppTextStyles.headingSmall),
                              const SizedBox(width: 6),
                              if (isActivelyVibrating)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Syncing',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Feel the music',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CustomBeatSyncSwitch(
                      value: isEnabled,
                      onChanged: (val) {
                        AppHaptics.selection();
                        ref.read(beatSyncSettingsProvider.notifier).setEnabled(val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row: Status & visual wave
                Row(
                  children: [
                    Text(
                      isEnabled
                          ? 'Vibrations follow the beat'
                          : 'Vibration is off',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isEnabled ? AppColors.purple : AppColors.textMuted,
                        fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    _MiniWaveBar(isActive: isEnabled),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomBeatSyncSwitch extends StatelessWidget {
  const _CustomBeatSyncSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? const LinearGradient(
                  colors: [AppColors.purple, AppColors.blue],
                )
              : null,
          color: value ? null : const Color(0xFFE2E4EB),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniWaveBar extends StatelessWidget {
  const _MiniWaveBar({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final heights = [8.0, 14.0, 10.0, 16.0];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: heights[i],
          decoration: BoxDecoration(
            color: isActive ? AppColors.purple : AppColors.disabled,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
