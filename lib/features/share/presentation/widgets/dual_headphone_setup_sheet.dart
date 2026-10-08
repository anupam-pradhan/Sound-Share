import 'package:flutter/material.dart';
import 'package:soundshare/core/utils/android_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/core/widgets/app_sheet.dart';
import 'package:soundshare/core/widgets/surface.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/dual_audio_status.dart';

/// Interactive modal sheet guiding the user to connect two Bluetooth headphones
/// with phone-specific instructions (Samsung, Pixel, Xiaomi, OnePlus, Motorola).
class DualHeadphoneSetupSheet extends ConsumerWidget {
  const DualHeadphoneSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.medium();
    return AppSheet.show<void>(
      context,
      (_) => const DualHeadphoneSetupSheet(),
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

    final manufacturer =
        capabilityAsync.valueOrNull?.deviceManufacturer ?? 'Android';
    final androidVersion = capabilityAsync.valueOrNull?.androidVersion ?? 30;
    final status = ref.watch(dualAudioStatusProvider).valueOrNull ??
        DualAudioStatus.unknown;
    final isSamsung = status.mode == DualAudioMode.samsungDualAudio ||
        manufacturer.toLowerCase().contains('samsung');

    // Filter available audio devices that are not already connected
    final availableToConnect = discovered.where((d) {
      final isAlreadyConnected = connected.any(
          (c) => c.id == d.id || c.name.toLowerCase() == d.name.toLowerCase());
      return !isAlreadyConnected && d.name.trim().isNotEmpty;
    }).toList();

    return AppSheet(
        title: 'Play on two headphones',
        subtitle:
            '$manufacturer • Android ${androidReleaseName(androidVersion)}',
        icon: Icons.headphones_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current connection status banner
            Entrance(child: _buildStatusBanner(status, connected, isDark)),

            const SizedBox(height: 18),

            // Phone-specific instructions card
            Entrance(index: 1, child: _buildModeGuide(status, isDark)),

            const SizedBox(height: 20),

            // Quick connect paired devices list
            if (availableToConnect.isNotEmpty) ...[
              const SectionLabel('Paired headphones'),
              ...availableToConnect.take(4).map((d) => _buildQuickConnectTile(
                    context: context,
                    ref: ref,
                    device: d,
                    isDark: isDark,
                  )),
              const SizedBox(height: 18),
            ],

            // Action Buttons Grid
            const SectionLabel('Phone settings'),

            // 1. Open Media Output Selector
            _buildActionButton(
              context: context,
              icon: Icons.speaker_group_rounded,
              title: 'Open Media Output Panel',
              subtitle:
                  isSamsung || status.mode == DualAudioMode.oplusAudioSharing
                      ? 'Tick both headphones to play on both'
                      : 'Choose which headphone plays, or tick both if offered',
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

            // 3. Android 15+/16 LE Audio sharing
            if (status.mode == DualAudioMode.leAudioSharing) ...[
              _buildActionButton(
                context: context,
                icon: Icons.podcasts_rounded,
                title: 'Open Audio Sharing',
                subtitle: 'Android plays to both LE Audio earbuds at once',
                color: AppColors.success,
                isDark: isDark,
                onTap: () {
                  AppHaptics.light();
                  service.openAudioSharingSettings();
                },
              ),
              const SizedBox(height: 10),
            ],

            // 4. Universal Peer Share Fallback Hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B192A) : const Color(0xFFF5F3FF),
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
                          'Another option: Universal Peer Share',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Works on every phone: a friend joins your Wi-Fi/Hotspot and listens on their own phone and headphones.',
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
        ));
  }

  Widget _buildStatusBanner(DualAudioStatus status,
      List<BluetoothDeviceModel> connected, bool isDark) {
    final count = connected.length;
    final (Color color, IconData icon, String message) = switch (status.mode) {
      DualAudioMode.appMirroring => (
          AppColors.success,
          Icons.check_circle_rounded,
          'Two separate outputs found. Tap "Share Audio" and both will play.',
        ),
      DualAudioMode.singleActiveOnly => (
          const Color(0xFFD69E2E),
          Icons.info_outline_rounded,
          'Both headphones are connected, but Android only sends music to one '
              'Bluetooth headphone at a time on this phone.',
        ),
      DualAudioMode.samsungDualAudio ||
      DualAudioMode.oplusAudioSharing ||
      DualAudioMode.leAudioSharing =>
        (
          AppColors.blue,
          Icons.info_rounded,
          count >= 2
              ? 'Your phone can play to both. Follow the steps below.'
              : 'Connect your 2nd headphone, then follow the steps below.',
        ),
      DualAudioMode.needSecondDevice => (
          AppColors.blue,
          Icons.info_outline_rounded,
          count == 1
              ? '1 headphone connected ("${connected.first.name}"). Connect a 2nd one.'
              : 'No headphones connected yet. Turn on Bluetooth and connect one.',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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

  Widget _buildModeGuide(DualAudioStatus status, bool isDark) {
    final (String title, List<String> steps) = switch (status.mode) {
      DualAudioMode.appMirroring => (
          'Ready to play on both',
          [
            'Tap "Share Audio" in SoundShare and allow audio capture.',
            'Play music in any app — SoundShare mirrors it to the second output.',
          ],
        ),
      DualAudioMode.samsungDualAudio => (
          'Samsung Dual Audio',
          [
            'Connect both Bluetooth headphones in Settings > Bluetooth.',
            'Tap "Open Media Output Panel" below.',
            'Tick the circle next to BOTH headphones.',
            'Play music — both headphones play together.',
          ],
        ),
      DualAudioMode.oplusAudioSharing => (
          'OnePlus / OPPO / Realme Audio Sharing',
          [
            'Connect both Bluetooth headphones in Settings > Bluetooth.',
            'Tap "Open Media Output Panel" below.',
            'In the dialog that opens, tap "Add device to group" next to your 2nd headphone.',
            'Play music — both headphones play together.',
            'Both playing? Done — the app may still say "Standby" because Android hides grouped devices from apps.',
          ],
        ),
      DualAudioMode.leAudioSharing => (
          'Android Audio Sharing (LE Audio)',
          [
            'Tap "Open Audio Sharing" below and turn it on.',
            'Put the 2nd pair of LE Audio earbuds in pairing mode and add it.',
            'Play music — both pairs play together.',
          ],
        ),
      DualAudioMode.singleActiveOnly || DualAudioMode.needSecondDevice => (
          'What works on this phone',
          [
            'Plug a USB-C Bluetooth audio transmitter into the phone and pair the 2nd headphone to it — SoundShare then plays to both automatically.',
            'Or use 1 Bluetooth + 1 wired / USB-C headphone: SoundShare plays to both.',
            'Tap "Open Media Output Panel": if you see a checkbox or "+" next to the 2nd headphone, tick it — your phone supports dual audio.',
            'Or use headphones/speakers with their own share/party mode (JBL, Sony, Marshall).',
            'Two regular Bluetooth headphones on one phone need Samsung Dual Audio or Android 16 LE Audio sharing — no app can unlock this.',
          ],
        ),
    };

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
                  title,
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
          for (int i = 0; i < steps.length; i++)
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
              await ref
                  .read(connectedDevicesProvider.notifier)
                  .refreshConnectedDevices();
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
    return PressableScale(
      onTap: onTap,
      child: InkWell(
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
      ),
    );
  }
}
