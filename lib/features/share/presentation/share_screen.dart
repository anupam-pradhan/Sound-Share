import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/skeleton_loader.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/animated_widgets.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'widgets/bluetooth_device_card.dart';
import 'widgets/connected_devices_panel.dart';
import 'widgets/share_audio_button.dart';
import 'widgets/share_hero_card.dart';
import 'widgets/audio_mode_selector_card.dart';
import 'widgets/dual_headphone_setup_sheet.dart';
// [COMMENTED OUT - BeatSyncCard disabled per SoundShare-only configuration]
// import '../../beatsync/presentation/widgets/beatsync_card.dart';
import '../../../core/widgets/theme_toggle_button.dart';

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btAdapterState = ref.watch(bluetoothAdapterStateProvider);
    final isScanning = ref.watch(isScanningProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final sharingState = ref.watch(audioSharingStateProvider);
    final sharingDuration = ref.watch(sharingDurationProvider);
    final activeMode = ref.watch(activeSharingModeProvider);
    final peersCount = ref.watch(connectedPeersCountProvider).valueOrNull ?? 0;

    final btEnabled = btAdapterState.valueOrNull == BluetoothAdapterState.on;

    // Two headphones connected but Android only plays one: show what works on this phone
    ref.listen(dualAudioUnavailableProvider, (_, next) {
      if (next.hasValue && context.mounted) {
        ref.invalidate(dualAudioStatusProvider);
        DualHeadphoneSetupSheet.show(context);
      }
    });

    final isWifi = activeMode == AudioSharingMode.universalPeerShare;
    final showDevices = btEnabled || isWifi;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Entrance(child: _AppHeader()),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Entrance(
                      index: 1,
                      child: ShareHeroCard(
                        connectedDevices: connectedDevices,
                        sharingState: sharingState,
                        sharingDuration: sharingDuration,
                        btEnabled: btEnabled,
                        activeMode: activeMode,
                        peersCount: peersCount,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Entrance(index: 2, child: AudioModeSelectorCard()),
                    Reveal(
                      visible: showDevices,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          Entrance(
                            index: 3,
                            child: ConnectedDevicesPanel(
                              connectedDevices: connectedDevices,
                              sharingState: sharingState,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Entrance(
                            index: 4,
                            child: _BluetoothDevicesSection(
                              isScanning: isScanning.valueOrNull ?? false,
                              devices: discoveredDevices,
                              connectedDevices: connectedDevices,
                              onScan: () {
                                final notifier = ref
                                    .read(discoveredDevicesProvider.notifier);
                                if (isScanning.valueOrNull == true) {
                                  notifier.stopScan();
                                } else {
                                  notifier.startScan();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Share Audio button ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Entrance(
                index: 5,
                offset: 28,
                child: ShareAudioButton(
                  state: showDevices
                      ? sharingState
                      : AudioSharingState.unavailable,
                  sharingDuration: sharingDuration,
                  onShare: () {
                    ref.read(audioSharingStateProvider.notifier).startSharing();
                  },
                  onStop: () {
                    ref.read(audioSharingStateProvider.notifier).stopSharing();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// App Header
// ──────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              AppAssets.logo,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),

          // Name + tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SoundShare', style: AppTextStyles.headingMedium),
                Text('Connect multiple devices', style: AppTextStyles.tagline),
              ],
            ),
          ),

          // Animated 3D Dark/Light mode toggle
          const ThemeToggleIconButton(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Bluetooth devices section
// ──────────────────────────────────────────────

class _BluetoothDevicesSection extends StatelessWidget {
  const _BluetoothDevicesSection({
    required this.isScanning,
    required this.devices,
    required this.connectedDevices,
    required this.onScan,
  });

  final bool isScanning;
  final List<dynamic> devices;
  final List<BluetoothDeviceModel> connectedDevices;
  final VoidCallback onScan;

  String _normalizeDeviceName(String name) {
    return name
        .replaceAll(
            RegExp(r'\s*\((?:left|right|l|r)\)', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'[_\-](?:left|right|l|r)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+(?:left|right|l|r)$', caseSensitive: false), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final connectedIds = connectedDevices.map((c) => c.id).toSet();
    final connectedNames = connectedDevices
        .map((c) => _normalizeDeviceName(c.name).toLowerCase())
        .toSet();

    final availableDevices = <BluetoothDeviceModel>[];
    for (final raw in devices) {
      if (raw is! BluetoothDeviceModel) continue;
      final name = raw.name.trim();
      if (name.isEmpty ||
          name.toLowerCase() == 'unknown device' ||
          name.toLowerCase().startsWith('unknown')) {
        continue;
      }
      final normName = _normalizeDeviceName(name).toLowerCase();
      // Skip if already connected (actively shown in ConnectedDevicesPanel above)
      if (connectedIds.contains(raw.id) || connectedNames.contains(normName)) {
        continue;
      }
      // Deduplicate inside available list
      if (!availableDevices.any((ex) =>
          ex.id == raw.id ||
          _normalizeDeviceName(ex.name).toLowerCase() == normName)) {
        availableDevices.add(raw);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          availableDevices.isEmpty
              ? 'Nearby devices'
              : 'Nearby devices  •  ${availableDevices.length}',
          trailing: SectionAction(
            label: isScanning ? 'Scanning' : 'Scan',
            icon: Icons.bluetooth_searching_rounded,
            leading: isScanning
                ? const ScanningAnimation(size: 14, color: AppColors.purple)
                : null,
            onTap: () {
              AppHaptics.light();
              onScan();
            },
          ),
        ),

        // Device list (only show real un-connected devices)
        if (availableDevices.isEmpty && !isScanning)
          _EmptyDevicesCard(hasConnected: connectedDevices.isNotEmpty)
        else ...[
          for (int i = 0; i < availableDevices.length; i++)
            BluetoothDeviceCard(
              device: availableDevices[i],
              animationDelay: Duration(milliseconds: i * 80),
            ),
        ],

        if (isScanning) ...[
          const BluetoothDeviceSkeletonCard(),
          const BluetoothDeviceSkeletonCard(),
        ],
      ],
    );
  }
}

class _EmptyDevicesCard extends ConsumerWidget {
  const _EmptyDevicesCard({this.hasConnected = false});
  final bool hasConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasConnected
                ? Icons.check_circle_outline_rounded
                : Icons.bluetooth_audio_rounded,
            size: 36,
            color: hasConnected ? AppColors.success : AppColors.purple,
          ),
          const SizedBox(height: 10),
          Text(
            hasConnected
                ? 'All paired headphones are active above'
                : 'No paired audio devices found nearby',
            style: AppTextStyles.headingSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hasConnected
                ? 'To connect a 2nd headphone, put it in pairing mode and pair in Settings.'
                : 'Put your Bluetooth headphones in pairing mode or connect them in Settings.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              AppHaptics.light();
              ref.read(audioSharingServiceProvider).openBluetoothSettings();
            },
            icon: const Icon(Icons.settings_bluetooth_rounded, size: 16),
            label: Text(hasConnected
                ? 'Pair Another Headphone'
                : 'Pair in Bluetooth Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF3B3754)
                    : AppColors.purple.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
