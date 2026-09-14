import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../features/bluetooth/domain/bluetooth_providers.dart';
import '../../../features/audio_sharing/domain/audio_sharing_providers.dart';
import '../../../features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
// [COMMENTED OUT - BeatSync & Spatial Audio disabled per SoundShare-only configuration]
// import '../../../features/beatsync/domain/beatsync_providers.dart';
// import '../../../features/spatial_audio/domain/spatial_audio_providers.dart';
import 'widgets/about_soundshare_sheet.dart';
import 'widgets/privacy_policy_sheet.dart';
import 'widgets/rate_app_dialog.dart';
import '../../../app/theme/theme_provider.dart';

// ──────────────────────────────────────────────
// Preferences providers
// ──────────────────────────────────────────────

final autoConnectProvider = StateNotifierProvider<_PrefNotifier, bool>((ref) {
  return _PrefNotifier('auto_connect', defaultValue: false);
});

final stayVisibleProvider = StateNotifierProvider<_PrefNotifier, bool>((ref) {
  return _PrefNotifier('stay_visible', defaultValue: false);
});

final notificationsEnabledProvider = StateNotifierProvider<_PrefNotifier, bool>((ref) {
  return _PrefNotifier('notifications_enabled', defaultValue: true);
});

class _PrefNotifier extends StateNotifier<bool> {
  _PrefNotifier(this._key, {required bool defaultValue}) : super(defaultValue) {
    _load();
  }
  final String _key;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? state;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

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
    final autoConnect = ref.watch(autoConnectProvider);
    final stayVisible = ref.watch(stayVisibleProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.textPrimary,
                    onPressed: () {
                      AppHaptics.light();
                      context.go('/share');
                    },
                  ),
                  Text('Settings', style: AppTextStyles.headingLarge),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Bluetooth section
                    _SettingsCard(
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

                    // Audio section
                    _SettingsCard(
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
                            ref.read(audioSharingServiceProvider).openMediaOutputSelector();
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
                        _Divider(),
                        _SettingsRow(
                          icon: Icons.high_quality_rounded,
                          iconColor: AppColors.purple,
                          label: 'Audio quality',
                          trailing: Text(
                            'Standard',
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Preferences section
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.notifications_active_outlined,
                          iconColor: AppColors.blue,
                          label: 'Notifications',
                          subtitle: 'Show playback controls in status bar',
                          trailing: Switch(
                            value: notificationsEnabled,
                            onChanged: (_) => ref
                                .read(notificationsEnabledProvider.notifier)
                                .toggle(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        _Divider(),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          iconColor: AppColors.purple,
                          label: 'Dark mode',
                          subtitle: 'Switch between dark and light appearance',
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (_) {
                              AppHaptics.light();
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        _Divider(),
                        _SettingsRow(
                          icon: Icons.link_rounded,
                          iconColor: AppColors.blue,
                          label: 'Auto connect',
                          subtitle: 'Connect last used device when available',
                          trailing: Switch(
                            value: autoConnect,
                            onChanged: (_) =>
                                ref.read(autoConnectProvider.notifier).toggle(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        _Divider(),
                        _SettingsRow(
                          icon: Icons.visibility_outlined,
                          iconColor: AppColors.blue,
                          label: 'Stay visible',
                          subtitle: 'Allow nearby devices to discover SoundShare',
                          trailing: Switch(
                            value: stayVisible,
                            onChanged: (_) =>
                                ref.read(stayVisibleProvider.notifier).toggle(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Legal & About
                    _SettingsCard(
                      children: [
                        InkWell(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber),
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
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          onTap: () => AboutSoundShareSheet.show(
                            context,
                            version: _version,
                          ),
                          child: _SettingsRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.purple,
                            label: 'About SoundShare',
                            subtitle: 'Crafted by Anupam Pradhan • No Ads',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _version.isNotEmpty
                                      ? 'v$_version'
                                      : 'v1.0.0',
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
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
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
