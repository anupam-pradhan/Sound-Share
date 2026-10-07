import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../features/bluetooth/domain/bluetooth_providers.dart';
import '../../../features/audio_sharing/domain/audio_sharing_providers.dart';
import '../../../features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';
// [COMMENTED OUT - BeatSync & Spatial Audio disabled per SoundShare-only configuration]
// import '../../../features/beatsync/domain/beatsync_providers.dart';
// import '../../../features/spatial_audio/domain/spatial_audio_providers.dart';
import 'widgets/about_soundshare_sheet.dart';
import 'widgets/privacy_policy_sheet.dart';
import 'widgets/rate_app_dialog.dart';
import '../../../app/theme/theme_provider.dart';

// ──────────────────────────────────────────────
// Settings Screen
// ──────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final btState = ref.watch(bluetoothAdapterStateProvider);
    final sharingState = ref.watch(audioSharingStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    final btEnabled = btState.valueOrNull == BluetoothAdapterState.on;
    final activeMode = ref.watch(activeSharingModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Entrance(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Text('Settings', style: AppTextStyles.headingLarge),
            )),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SectionLabel('Connection'),
                    _SettingsCard(
                      index: 1,
                      children: [
                        _SettingsRow(
                          icon: Icons.bluetooth_rounded,
                          iconColor: AppColors.blue,
                          label: 'Bluetooth',
                          trailing: Text(
                            btEnabled ? 'On' : 'Off',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: btEnabled
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const SectionLabel('Audio sharing'),
                    _SettingsCard(
                      index: 2,
                      children: [
                        _SettingsRow(
                          icon: Icons.graphic_eq_rounded,
                          iconColor: AppColors.purple,
                          label: 'Audio sharing',
                          trailing: Text(
                            _sharingLabel(sharingState),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: sharingState == AudioSharingState.sharing
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        /*
                        // [COMMENTED OUT - BeatSync & Spatial Audio disabled per SoundShare-only configuration]
                        _Divider(),
                        InkWell(
                          onTap: () {
                            AppHaptics.light();
                            context.push('/beatsync');
                          },
                          child: _SettingsRow(
                            icon: Icons.vibration_rounded,
                            iconColor: AppColors.purple,
                            label: 'BeatSync',
                            subtitle: 'Feel the music through vibrations',
                            trailing: ...
                          ),
                        ),
                        _Divider(),
                        InkWell(
                          onTap: () {
                            AppHaptics.light();
                            context.push('/spatial_audio');
                          },
                          child: _SettingsRow(
                            icon: Icons.spatial_audio_rounded,
                            iconColor: AppColors.purple,
                            label: '3D Spatial Audio',
                            subtitle: 'Immersive sound around you',
                            trailing: ...
                          ),
                        ),
                        */
                        _Divider(),
                        InkWell(
                          onTap: () {
                            AppHaptics.light();
                            ref
                                .read(audioSharingServiceProvider)
                                .openMediaOutputSelector();
                          },
                          child: const _SettingsRow(
                            icon: Icons.speaker_group_rounded,
                            iconColor: AppColors.purple,
                            label: 'Dual Audio & Output Devices',
                            subtitle: 'Switch or route audio across outputs',
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        _Divider(),
                        _SettingsRow(
                          icon: Icons.tune_rounded,
                          iconColor: AppColors.purple,
                          label: 'Sharing mode',
                          subtitle: activeMode.subtitle,
                          trailing: Text(
                            activeMode.title,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const SectionLabel('Appearance'),
                    _SettingsCard(
                      index: 3,
                      children: [
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          iconColor: AppColors.purple,
                          label: 'Dark mode',
                          subtitle: 'Switch between dark and light appearance',
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (_) {
                              AppHaptics.light();
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const SectionLabel('About'),
                    // Legal & About
                    _SettingsCard(
                      index: 4,
                      children: [
                        InkWell(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          onTap: () {
                            AppHaptics.light();
                            RateAppDialog.show(context);
                          },
                          child: const _SettingsRow(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber,
                            label: 'Rate SoundShare',
                            subtitle: 'Love the app? Leave a review',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded,
                                    size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded,
                                    size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded,
                                    size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded,
                                    size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _Divider(),
                        InkWell(
                          onTap: () {
                            AppHaptics.light();
                            PrivacyPolicySheet.show(context);
                          },
                          child: const _SettingsRow(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: AppColors.blue,
                            label: 'Privacy Policy',
                            subtitle: 'Zero tracking & local audio processing',
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        _Divider(),
                        InkWell(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          onTap: () => AboutSoundShareSheet.show(
                            context,
                            version: _version,
                          ),
                          child: _SettingsRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.purple,
                            label: 'About SoundShare',
                            subtitle: 'By Quick Media Solution',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _version.isNotEmpty ? 'v$_version' : 'v1.0.0',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sharingLabel(AudioSharingState state) {
    switch (state) {
      case AudioSharingState.sharing:
        return 'Active';
      case AudioSharingState.ready:
        return 'Available';
      case AudioSharingState.starting:
        return 'Starting';
      case AudioSharingState.stopping:
        return 'Stopping';
      default:
        return 'Unavailable';
    }
  }
}

// ──────────────────────────────────────────────
// Settings UI components
// ──────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, this.index = 0});
  final List<Widget> children;

  /// Stagger position for the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      index: index,
      child: Surface(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 60,
      endIndent: 0,
      color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
    );
  }
}
