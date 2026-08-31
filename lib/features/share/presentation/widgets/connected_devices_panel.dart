import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/audio_flow_animation.dart';
import '../../../features/bluetooth/domain/bluetooth_device_model.dart';
import '../../../features/audio_sharing/domain/audio_sharing_service.dart';

/// Panel showing connected device count and audio flow animation.
class ConnectedDevicesPanel extends StatelessWidget {
  const ConnectedDevicesPanel({
    super.key,
    required this.connectedDevices,
    required this.sharingState,
  });

  final List<BluetoothDeviceModel> connectedDevices;
  final AudioSharingState sharingState;

  int get _count => connectedDevices.length;
  bool get _isSharing => sharingState == AudioSharingState.sharing;
  BluetoothDeviceModel? get _firstDevice =>
      connectedDevices.isNotEmpty ? connectedDevices.first : null;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isSharing
              ? AppColors.purple.withOpacity(0.25)
              : AppColors.cardBorder,
          width: _isSharing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSharing
                ? AppColors.purple.withOpacity(0.08)
                : AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Count and subtitle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _header(),
          ),

          const SizedBox(height: 16),

          // Audio flow visualization
          AudioFlowAnimation(
            isSharing: _isSharing,
            connectedDevice: _firstDevice,
            height: 90,
          ),
        ],
      ),
    );
  }

  Widget _header() {
    if (_isSharing) {
      return Column(
        key: const ValueKey('sharing'),
        children: [
          Text(
            '${_count} ${_count == 1 ? 'device' : 'devices'} connected',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Sharing audio',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      );
    }

    if (_count > 0) {
      return Column(
        key: const ValueKey('ready'),
        children: [
          Text(
            '${_count} ${_count == 1 ? 'device' : 'devices'} connected',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 3),
          Text(
            'You can now share audio.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('empty'),
      children: [
        Text(
          '0 devices connected',
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 3),
        Text(
          'Connect a device to start sharing audio.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
