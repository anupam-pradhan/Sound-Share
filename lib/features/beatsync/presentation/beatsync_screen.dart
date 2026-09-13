import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../domain/beat_event.dart';
import '../domain/beatsync_providers.dart';
import 'widgets/beatsync_visualizer.dart';

/// Full control screen for the BeatSync audio-haptic engine.
class BeatSyncScreen extends ConsumerStatefulWidget {
  const BeatSyncScreen({super.key});

  @override
  ConsumerState<BeatSyncScreen> createState() => _BeatSyncScreenState();
}

class _BeatSyncScreenState extends ConsumerState<BeatSyncScreen> {
  bool _testingPulse = false;

  Future<void> _triggerTestPulse() async {
    final capsAsync = ref.read(hapticCapabilitiesProvider);
    final isAvailable = capsAsync.valueOrNull?.available ?? true;

    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Haptics unavailable',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "This device doesn't support the required vibration controls.",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _testingPulse = true);
    await ref.read(beatSyncStatusProvider.notifier).testPulse();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _testingPulse = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(beatSyncSettingsProvider);
    final status = ref.watch(beatSyncStatusProvider);
    final capsAsync = ref.watch(hapticCapabilitiesProvider);
    final isEnabled = settings.enabled;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: theme.colorScheme.onSurface,
                    onPressed: () {
                      AppHaptics.light();
                      context.pop();
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BeatSync', style: AppTextStyles.headingLarge),
                      Text('Feel the music', style: AppTextStyles.tagline),
                    ],
                  ),
                  const Spacer(),
                  // Master Switch
                  _BeatSyncToggle(
                    value: isEnabled,
                    onChanged: (val) {
                      AppHaptics.selection();
                      ref.read(beatSyncSettingsProvider.notifier).setEnabled(val);
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Main Synchronized Waveform Visualizer
                    BeatSyncVisualizer(
                      height: 150,
                      isActive: isEnabled && status != BeatSyncStatus.off,
                    ),

                    const SizedBox(height: 14),

                    // Status Indicator Badge
                    Center(child: _StatusBadge(status: status, isEnabled: isEnabled)),

                    const SizedBox(height: 20),

                    // Unsupported Banner if vibration hardware unavailable
                    capsAsync.when(
                      data: (caps) {
                        if (!caps.available) {
                          return const _UnavailableCard(
                            title: 'Haptics unavailable',
                            subtitle:
                                "This device doesn't support the required vibration controls.",
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Controls Section
                    Text('Engine Controls', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : AppColors.cardShadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Haptic Intensity
                          _SegmentedControlRow(
                            label: 'Haptic Intensity',
                            subtitle: 'Vibration strength on detected beats',
                            options: const ['Low', 'Medium', 'High'],
                            selectedIndex: _intensityToIndex(settings.intensity),
                            onSelected: (idx) {
                              AppHaptics.selection();
                              ref
                                  .read(beatSyncSettingsProvider.notifier)
                                  .setIntensity(_indexToIntensity(idx));
                            },
                          ),

                          Divider(
                            height: 24,
                            color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
                          ),

                          // Beat Sensitivity
                          _SegmentedControlRow(
                            label: 'Beat Sensitivity',
                            subtitle: 'Threshold for kick and transient trigger',
                            options: const ['Low', 'Medium', 'High'],
                            selectedIndex: _sensitivityToIndex(settings.sensitivity),
                            onSelected: (idx) {
                              AppHaptics.selection();
                              ref
                                  .read(beatSyncSettingsProvider.notifier)
                                  .setSensitivity(_indexToSensitivity(idx));
                            },
                          ),

                          Divider(
                            height: 24,
                            color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
                          ),

                          // Bass Boost
                          _SegmentedControlRow(
                            label: 'Bass Response',
                            subtitle: 'Sub-bass emphasis for low-frequency drops',
                            options: const ['Off', 'Normal', 'Strong'],
                            selectedIndex: _bassToIndex(settings.bassBoost),
                            onSelected: (idx) {
                              AppHaptics.selection();
                              ref
                                  .read(beatSyncSettingsProvider.notifier)
                                  .setBassBoost(_indexToBass(idx));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test Vibration Button
                    GestureDetector(
                      onTap: _triggerTestPulse,
                      child: AnimatedScale(
                        scale: _testingPulse ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.purple, AppColors.blue],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _testingPulse
                                      ? Icons.vibration_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _testingPulse
                                      ? 'Testing Vibration...'
                                      : 'Test Vibration',
                                  style: AppTextStyles.buttonLarge.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Audio Source Information Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B1A28)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2B293E)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How BeatSync Works',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'BeatSync analyzes real PCM audio frequencies and generates synchronized haptic pulses using Android hardware vibration. Rate limiters protect battery and hand comfort.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _intensityToIndex(double v) {
    if (v <= 0.6) return 0;
    if (v >= 1.4) return 2;
    return 1;
  }

  double _indexToIntensity(int idx) {
    switch (idx) {
      case 0:
        return 0.5;
      case 2:
        return 1.5;
      default:
        return 1.0;
    }
  }

  int _sensitivityToIndex(double v) {
    if (v >= 1.3) return 0; // High threshold = low sensitivity
    if (v <= 0.8) return 2; // Low threshold = high sensitivity
    return 1;
  }

  double _indexToSensitivity(int idx) {
    switch (idx) {
      case 0:
        return 1.4;
      case 2:
        return 0.7;
      default:
        return 1.0;
    }
  }

  int _bassToIndex(double v) {
    if (v <= 1.1) return 0;
    if (v >= 1.5) return 2;
    return 1;
  }

  double _indexToBass(int idx) {
    switch (idx) {
      case 0:
        return 1.0;
      case 2:
        return 1.6;
      default:
        return 1.3;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isEnabled});
  final BeatSyncStatus status;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return _pill('BeatSync Off', AppColors.textMuted, false);
    }

    switch (status) {
      case BeatSyncStatus.active:
        return _pill('BeatSync Active', AppColors.success, true);
      case BeatSyncStatus.analyzing:
        return _pill('Listening for beats...', AppColors.purple, true);
      case BeatSyncStatus.ready:
        return _pill('BeatSync Ready', AppColors.purple, false);
      case BeatSyncStatus.unavailable:
        return _pill('BeatSync unavailable', AppColors.error, false);
      case BeatSyncStatus.off:
        return _pill('BeatSync Off', AppColors.textMuted, false);
    }
  }

  Widget _pill(String text, Color color, bool pulse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControlRow extends StatelessWidget {
  const _SegmentedControlRow({
    required this.label,
    required this.subtitle,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final String subtitle;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(options.length, (i) {
              final isSel = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSel
                          ? const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? AppColors.purple : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BeatSyncToggle extends StatelessWidget {
  const _BeatSyncToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 50,
        height: 28,
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
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
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

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
