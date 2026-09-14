import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/skeleton_loader.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/animated_widgets.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'widgets/connected_audio_card.dart';
import 'widgets/bluetooth_device_card.dart';
import 'widgets/connected_devices_panel.dart';
import 'widgets/share_audio_button.dart';
import 'widgets/audio_mode_selector_card.dart';
import 'widgets/peer_sharing_qr_dialog.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            const _AppHeader(),

            // ── Scrollable content ───────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Smart Audio Sharing Mode Selector ────
                    const AudioModeSelectorCard(),

                    const SizedBox(height: 14),

                    // Universal Peer Share Invite Card
                    if (activeMode == AudioSharingMode.universalPeerShare) ...[
                      _PeerShareInviteBanner(
                        isSharing: sharingState == AudioSharingState.sharing,
                        peersCount: peersCount,
                        onOpenQr: () => PeerSharingQrDialog.show(context),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Bluetooth off / no permission banner
                    if (!btEnabled && activeMode != AudioSharingMode.universalPeerShare)
                      _BluetoothOffBanner(
                        onEnable: () async {
                          try {
                            await FlutterBluePlus.turnOn();
                          } catch (_) {}
                        },
                      ),

                    if (btEnabled || activeMode == AudioSharingMode.universalPeerShare) ...[
                      // Audio Source card (This Phone)
                      ConnectedAudioCard(
                        deviceType: BluetoothDeviceType.phone,
                        deviceName: connectedDevices.isNotEmpty
                            ? 'Streaming to ${connectedDevices.length} ${connectedDevices.length == 1 ? 'headphone' : 'headphones'}'
                            : (activeMode == AudioSharingMode.universalPeerShare
                                ? 'This Phone (Wi-Fi Broadcast)'
                                : 'This Phone (Media Audio)'),
                        isConnected: btEnabled || activeMode == AudioSharingMode.universalPeerShare,
                      ),

                      const SizedBox(height: 14),

                      // Connected Headphones Panel (Dual Headphone Manager)
                      ConnectedDevicesPanel(
                        connectedDevices: connectedDevices,
                        sharingState: sharingState,
                      ),

                      const SizedBox(height: 14),

                      // Quick connect & Dual Audio Action Bar
                      const _DualAudioQuickBar(),

                      const SizedBox(height: 18),

                      // Bluetooth devices section
                      _BluetoothDevicesSection(
                        isScanning: isScanning.valueOrNull ?? false,
                        devices: discoveredDevices,
                        onScan: () {
                          if (isScanning.valueOrNull == true) {
                            ref
                                .read(discoveredDevicesProvider.notifier)
                                .stopScan();
                          } else {
                            ref
                                .read(discoveredDevicesProvider.notifier)
                                .startScan();
                          }
                        },
                      ),

                      const SizedBox(height: 24),
                    ],

                    if (!btEnabled) ...[
                      // [COMMENTED OUT - BeatSyncCard per SoundShare-only configuration]
                      // const BeatSyncCard(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // ── Share Audio button ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ShareAudioButton(
                state: btEnabled ? sharingState : AudioSharingState.unavailable,
                sharingDuration: sharingDuration,
                onShare: () {
                  ref.read(audioSharingStateProvider.notifier).startSharing();
                },
                onStop: () {
                  ref.read(audioSharingStateProvider.notifier).stopSharing();
                },
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
    required this.onScan,
  });

  final bool isScanning;
  final List<dynamic> devices;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final namedDevices = devices
        .where((d) =>
            d.name != null &&
            (d.name as String).trim().isNotEmpty &&
            (d.name as String).toLowerCase() != 'unknown device' &&
            !(d.name as String).toLowerCase().startsWith('unknown'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text('Bluetooth devices', style: AppTextStyles.headingSmall),
            const Spacer(),
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                onScan();
              },
              child: Row(
                children: [
                  if (isScanning)
                    const ScanningAnimation(size: 14, color: AppColors.purple)
                  else
                    const Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 16,
                      color: AppColors.purple,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isScanning ? 'Scanning...' : 'Scan',
                    style: AppTextStyles.buttonMedium.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Device list (only show real named devices)
        if (namedDevices.isEmpty && !isScanning)
          _EmptyDevicesCard()
        else ...[
          for (int i = 0; i < namedDevices.length; i++)
            BluetoothDeviceCard(
              device: namedDevices[i] as dynamic,
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
          const Icon(
            Icons.bluetooth_audio_rounded,
            size: 36,
            color: AppColors.purple,
          ),
          const SizedBox(height: 10),
          Text(
            'No paired audio devices found nearby',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Put your Bluetooth headphones in pairing mode or connect them in Settings.',
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
            label: const Text('Pair in Bluetooth Settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              side: BorderSide(
                color: isDark ? const Color(0xFF3B3754) : AppColors.purple.withValues(alpha: 0.3),
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


// ──────────────────────────────────────────────
// Bluetooth off banner
// ──────────────────────────────────────────────

class _BluetoothOffBanner extends StatelessWidget {
  const _BluetoothOffBanner({required this.onEnable});
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth is turned off',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Turn on Bluetooth to find audio devices.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEnable,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Turn On',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [COMMENTED OUT - Web/QR Broadcast deferred per SoundShare Headphone Connect focus]
/*
class _BroadcastLiveCard extends ConsumerWidget {
  const _BroadcastLiveCard({this.broadcastUrl});
  final String? broadcastUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19162C) : const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live Audio Broadcast Active',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
              ),
              const Spacer(),
              const Icon(Icons.wifi_tethering_rounded, color: AppColors.purple, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Friends on the same Wi-Fi or Hotspot can open this link in any browser to listen along:',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF100E1C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    broadcastUrl ?? 'Preparing broadcast stream...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (broadcastUrl != null)
                  GestureDetector(
                    onTap: () {
                      AppHaptics.light();
                      Clipboard.setData(ClipboardData(text: broadcastUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Broadcast link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: AppColors.purple,
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
*/

// ──────────────────────────────────────────────
// Dual Audio Quick Actions Bar
// ──────────────────────────────────────────────

class _DualAudioQuickBar extends ConsumerWidget {
  const _DualAudioQuickBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                AppHaptics.light();
                ref.read(audioSharingServiceProvider).openBluetoothSettings();
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_audio_rounded,
                    size: 18,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pair New Device',
                    style: AppTextStyles.buttonMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 20,
            width: 1,
            color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                AppHaptics.light();
                ref.read(audioSharingServiceProvider).openMediaOutputSelector();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.speaker_group_rounded,
                    size: 18,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dual Audio / Output',
                    style: AppTextStyles.buttonMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Universal Peer Share Invite Banner
// ──────────────────────────────────────────────

class _PeerShareInviteBanner extends StatelessWidget {
  const _PeerShareInviteBanner({
    required this.isSharing,
    required this.peersCount,
    required this.onOpenQr,
  });

  final bool isSharing;
  final int peersCount;
  final VoidCallback onOpenQr;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSharing
              ? [
                  const Color(0xFF10B981).withOpacity(0.18),
                  const Color(0xFF059669).withOpacity(0.08),
                ]
              : [
                  AppColors.purple.withOpacity(0.15),
                  AppColors.blue.withOpacity(0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSharing
              ? const Color(0xFF10B981).withOpacity(0.4)
              : AppColors.purpleLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSharing
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : AppColors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSharing ? Icons.podcasts_rounded : Icons.qr_code_2_rounded,
              color: isSharing ? const Color(0xFF32D583) : AppColors.purpleLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSharing
                      ? (peersCount > 0
                          ? '$peersCount Friend${peersCount > 1 ? 's' : ''} Listening in Sync'
                          : 'Live Wi-Fi Stream Broadcasting')
                      : 'Share Audio with Any Friend',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSharing
                      ? 'Tap to show QR code or share link'
                      : 'Zero data • Works on 100% of phones',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFFA09EAE) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              AppHaptics.light();
              onOpenQr();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSharing ? const Color(0xFF10B981) : AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              isSharing ? 'QR Code' : 'Invite',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}


