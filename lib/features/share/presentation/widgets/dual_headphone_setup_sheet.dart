import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';

/// Interactive modal sheet guiding the user to connect two Bluetooth headphones
/// with phone-specific instructions (Samsung, Pixel, Xiaomi, OnePlus, Motorola).
class DualHeadphoneSetupSheet extends ConsumerWidget {
  const DualHeadphoneSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DualHeadphoneSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final capabilityAsync = ref.watch(audioSharingCapabilityProvider);
    final connected = ref.watch(connectedDevicesProvider);
    final discovered = ref.watch(discoveredDevicesProvider);
    final service = ref.read(audioSharingServiceProvider);

    final manufacturer = capabilityAsync.valueOrNull?.deviceManufacturer ?? 'Android';
    final androidVersion = capabilityAsync.valueOrNull?.androidVersion ?? 30;
    final isSamsung = capabilityAsync.valueOrNull?.hasSamsungDualAudio ??
        manufacturer.toLowerCase().contains('samsung');

    // Filter available audio devices that are not already connected
    final availableToConnect = discovered.where((d) {
      final isAlreadyConnected = connected.any((c) =>
          c.id == d.id || c.name.toLowerCase() == d.name.toLowerCase());
      return !isAlreadyConnected && d.name.trim().isNotEmpty;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161426) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF332F4C) : const Color(0xFFE2E0EC),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    color: AppColors.purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect 2 Headphones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$manufacturer • Android $androidVersion',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF9E9AA8) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current connection status banner
                  _buildStatusBanner(context, connected, isDark),

                  const SizedBox(height: 18),

                  // Phone-specific instructions card
                  _buildBrandInstructions(context, manufacturer, isSamsung, isDark),

                  const SizedBox(height: 20),

                  // Quick connect paired devices list
                  if (availableToConnect.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.bluetooth_searching_rounded,
                            size: 16, color: AppColors.purple),
                        const SizedBox(width: 6),
                        Text(
                          'Paired / Nearby Audio Devices',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...availableToConnect.take(4).map((d) => _buildQuickConnectTile(
                          context: context,
                          ref: ref,
                          device: d,
                          isDark: isDark,
                        )),
                    const SizedBox(height: 18),
                  ],

                  // Action Buttons Grid
                  Text(
                    'Quick Phone Actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. Open Media Output Selector
                  _buildActionButton(
                    context: context,
                    icon: Icons.speaker_group_rounded,
                    title: 'Open Media Output Panel',
                    subtitle: 'Check both headphones to stream audio simultaneously',
                    color: AppColors.purple,
                    isDark: isDark,
                    onTap: () {
                      AppHaptics.light();
                      service.openMediaOutputSelector();
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Open Bluetooth Settings
                  _buildActionButton(
                    context: context,
                    icon: Icons.bluetooth_rounded,
                    title: 'Open Bluetooth Settings',
                    subtitle: 'Pair or connect your 2nd headphone manually',
                    color: AppColors.blue,
                    isDark: isDark,
                    onTap: () {
                      AppHaptics.light();
                      service.openBluetoothSettings();
                    },
                  ),
                  const SizedBox(height: 10),

                  // 3. Open Developer Options (for Pixel, Xiaomi, OnePlus, Moto)
                  if (!isSamsung) ...[
                    _buildActionButton(
                      context: context,
                      icon: Icons.developer_mode_rounded,
                      title: 'Developer Options (Unlock Dual BT)',
                      subtitle:
                          'Set "Maximum connected Bluetooth audio devices" to 2 or 5',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      onTap: () {
                        AppHaptics.light();
                        service.openDeveloperSettings();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 4. Universal Peer Share Fallback Hint
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B192A) : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.wifi_tethering_rounded,
                          size: 20,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Guaranteed Fallback: Universal Peer Share',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'If your phone hardware cannot maintain two Bluetooth audio links, select "Universal Peer Share" at the top of SoundShare. A friend connects their phone to your Wi-Fi/Hotspot and listens on their headphones in real time!',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: isDark
                                      ? const Color(0xFF9E9AA8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
      BuildContext context, List<BluetoothDeviceModel> connected, bool isDark) {
    final count = connected.length;
    final isDualReady = count >= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDualReady
            ? AppColors.success.withValues(alpha: 0.12)
            : (count == 1
                ? AppColors.blue.withValues(alpha: 0.12)
                : AppColors.error.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDualReady
              ? AppColors.success.withValues(alpha: 0.3)
              : (count == 1
                  ? AppColors.blue.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDualReady
                ? Icons.check_circle_rounded
                : (count == 1 ? Icons.info_rounded : Icons.warning_rounded),
            color: isDualReady
                ? AppColors.success
                : (count == 1 ? AppColors.blue : AppColors.error),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDualReady
                  ? 'Dual Headphones Connected ($count active)! You are ready to share synchronized audio.'
                  : (count == 1
                      ? '1 Headphone connected ("${connected.first.name}"). Connect your 2nd headphone below.'
                      : 'No headphones connected yet. Turn on Bluetooth and connect your first headphone.'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandInstructions(
      BuildContext context, String manufacturer, bool isSamsung, bool isDark) {
    final lower = manufacturer.toLowerCase();

    String brandTitle;
    List<String> steps;

    if (isSamsung) {
      brandTitle = 'Samsung Dual Audio Instructions';
      steps = [
        'Connect both Bluetooth headphones in phone Settings > Bluetooth.',
        'Tap "Open Media Output Panel" below (or swipe down notification shade and tap Media Output).',
        'Check the circle next to BOTH connected headphones.',
        'Tap "Share Audio" in SoundShare to stream together!',
      ];
    } else if (lower.contains('google') || lower.contains('pixel')) {
      brandTitle = 'Google Pixel Dual Audio Instructions';
      steps = [
        'Pair both Bluetooth headphones in Settings > Connected devices.',
        'Tap "Open Media Output Panel" below to select multiple audio destinations.',
        'On Android 13/14+, you can also enable "Audio Sharing" in Connected devices settings.',
        'Both headphones will receive synchronized audio!',
      ];
    } else if (lower.contains('xiaomi') || lower.contains('redmi') || lower.contains('poco')) {
      brandTitle = 'Xiaomi / HyperOS / MIUI Instructions';
      steps = [
        'Tap "Developer Options" below.',
        'Scroll down and set "Maximum connected Bluetooth audio devices" to 2 or 5.',
        'Connect both headphones in Bluetooth Settings (now neither will disconnect!).',
        'Tap "Open Media Output Panel" to route audio to both.',
      ];
    } else if (lower.contains('oneplus') || lower.contains('oppo') || lower.contains('realme')) {
      brandTitle = 'OnePlus / OxygenOS / ColorOS Instructions';
      steps = [
        'Connect both Bluetooth headphones in Bluetooth Settings.',
        'If the first disconnects, tap "Developer Options" below and set "Max connected audio devices" to 2.',
        'Tap "Open Media Output Panel" below and select both audio outputs.',
      ];
    } else {
      brandTitle = '$manufacturer Dual Bluetooth Instructions';
      steps = [
        'If your phone disconnects the 1st headphone when connecting the 2nd, tap "Developer Options" below.',
        'Set "Maximum connected Bluetooth audio devices" from 1 to 2 (or 5).',
        'Connect both headphones in Bluetooth Settings.',
        'Tap "Open Media Output Panel" below to route to both headphones!',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B32) : const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2846) : const Color(0xFFE8E5F6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  brandTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFFCCC8D8)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickConnectTile({
    required BuildContext context,
    required WidgetRef ref,
    required BluetoothDeviceModel device,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B192A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF28243E) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones_rounded,
              size: 18, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              device.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              AppHaptics.light();
              final notifier = ref.read(discoveredDevicesProvider.notifier);
              await notifier.connectAudioDevice(device.id);
              await ref.read(connectedDevicesProvider.notifier).refreshConnectedDevices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B192A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF9E9AA8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
