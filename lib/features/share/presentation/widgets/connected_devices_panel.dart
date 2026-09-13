import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/audio_flow_animation.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';

/// Panel managing connected headphones for synchronized Dual Headphone audio sharing.
class ConnectedDevicesPanel extends ConsumerWidget {
  const ConnectedDevicesPanel({
    super.key,
    required this.connectedDevices,
    required this.sharingState,
  });

  final List<BluetoothDeviceModel> connectedDevices;
  final AudioSharingState sharingState;

  int get _count => connectedDevices.length;
  bool get _isSharing => sharingState == AudioSharingState.sharing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isSharing
              ? AppColors.purple.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
          width: _isSharing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSharing
                ? AppColors.purple.withValues(alpha: 0.14)
                : (isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.cardShadow),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: 14),

          // Audio Flow Animation
          AudioFlowAnimation(
            isSharing: _isSharing,
            connectedDevices: connectedDevices,
            height: 85,
          ),

          const SizedBox(height: 16),

          // Headphone Slots
          if (_count == 0)
            _buildEmptyPrompt(context, ref)
          else ...[
            // Headphone 1
            _buildHeadphoneCard(
              context: context,
              ref: ref,
              device: connectedDevices[0],
              index: 1,
              isDark: isDark,
            ),

            const SizedBox(height: 10),

            // Headphone 2 or "Connect 2nd Headphone" slot
            if (_count >= 2) ...[
              _buildHeadphoneCard(
                context: context,
                ref: ref,
                device: connectedDevices[1],
                index: 2,
                isDark: isDark,
              ),
              // Any additional devices
              for (int i = 2; i < connectedDevices.length; i++) ...[
                const SizedBox(height: 10),
                _buildHeadphoneCard(
                  context: context,
                  ref: ref,
                  device: connectedDevices[i],
                  index: i + 1,
                  isDark: isDark,
                ),
              ],
            ] else ...[
              _buildAddSecondHeadphoneSlot(context, ref, isDark),
            ],
          ],

          // Dual Audio OS hint
          const SizedBox(height: 14),
          _buildDualAudioHint(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (_isSharing) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _count >= 2
                          ? 'Dual Headphone Sharing Active'
                          : 'Headphone Audio Sharing Active',
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 15,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _count >= 2
                      ? 'Streaming synchronized audio to 2 headphones'
                      : 'Connected to 1 headphone (Connect 2nd for dual share)',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_count Active',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      );
    }

    if (_count >= 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dual Headphones Ready',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '2 Connected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Both headphones are connected and ready to share synchronized audio.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
          ),
        ],
      );
    }

    if (_count == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '1 Headphone Connected',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Single Mode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Connect a 2nd headphone below to enable Dual Audio Sharing.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Headphone-to-Headphone Share',
          style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(
          'Connect two Bluetooth headphones to share music together in real-time.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyPrompt(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.headphones_rounded,
            size: 32,
            color: AppColors.purple,
          ),
          const SizedBox(height: 8),
          const Text(
            'No Headphones Connected Yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Turn on your Bluetooth headphones or pair them in Bluetooth Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(audioSharingServiceProvider).openBluetoothSettings();
            },
            icon: const Icon(Icons.settings_bluetooth_rounded, size: 16),
            label: const Text('Pair Headphones'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadphoneCard({
    required BuildContext context,
    required WidgetRef ref,
    required BluetoothDeviceModel device,
    required int index,
    required bool isDark,
  }) {
    final isMuted = device.isMuted;
    final volume = isMuted ? 0.0 : device.volumeLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1D30) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header (Badge, Name, Disconnect button)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: index == 1
                      ? AppColors.purple
                      : (index == 2 ? AppColors.blue : AppColors.purpleLight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'HEADPHONE $index',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Disconnect button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(connectedDevicesProvider.notifier)
                      .disconnectDevice(device.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Individual Volume & Mute control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141322) : const Color(0xFFF7F6FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Mute toggle
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(connectedDevicesProvider.notifier)
                        .toggleMute(device.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isMuted
                          ? AppColors.error.withValues(alpha: 0.14)
                          : AppColors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isMuted
                          ? Icons.volume_off_rounded
                          : (volume > 0.5
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded),
                      size: 16,
                      color: isMuted ? AppColors.error : AppColors.purple,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Volume slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        pressedElevation: 2,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor:
                          isMuted ? AppColors.disabled : AppColors.purple,
                      inactiveTrackColor: isDark
                          ? const Color(0xFF2E2C44)
                          : AppColors.cardBorder,
                      thumbColor:
                          isMuted ? AppColors.disabled : AppColors.purple,
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: isMuted
                          ? null
                          : (val) {
                              ref
                                  .read(connectedDevicesProvider.notifier)
                                  .updateVolume(device.id, val);
                            },
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Volume percentage
                SizedBox(
                  width: 36,
                  child: Text(
                    isMuted ? 'Mute' : '${(volume * 100).toInt()}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isMuted ? AppColors.error : AppColors.textSecondary,
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

  Widget _buildAddSecondHeadphoneSlot(
      BuildContext context, WidgetRef ref, bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(audioSharingServiceProvider).openBluetoothSettings();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181726) : const Color(0xFFFAF9FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.blue.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+ Connect Headphone 2 for Dual Audio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pair your friend\'s headphones to share audio together',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualAudioHint(
      BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(audioSharingServiceProvider).openMediaOutputSelector();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161524) : const Color(0xFFF3F2F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Dual Audio routing active. Tap here to select Media Outputs.',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
