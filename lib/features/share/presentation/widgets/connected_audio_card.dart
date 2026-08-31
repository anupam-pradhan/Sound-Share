import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/bluetooth_device_icon.dart';
import '../../../features/bluetooth/domain/bluetooth_device_model.dart';

/// Card showing the user's currently active audio device.
class ConnectedAudioCard extends StatelessWidget {
  const ConnectedAudioCard({
    super.key,
    this.deviceName,
    this.batteryLevel,
    this.isConnected = false,
  });

  final String? deviceName;
  final int? batteryLevel;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device icon
          BluetoothDeviceIcon(
            type: BluetoothDeviceType.earbuds,
            size: 28,
            isConnected: isConnected,
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your audio', style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AnimatedStatusBadge(isActive: isConnected, size: 7),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? 'Connected to' : 'Not connected',
                      style: AppTextStyles.statusSuccess.copyWith(
                        color: isConnected
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  deviceName ?? 'No device connected',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'You are listening' : 'Connect a Bluetooth device',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          // Battery indicator
          if (batteryLevel != null && isConnected) ...[
            const SizedBox(width: 8),
            _BatteryChip(level: batteryLevel!),
          ],
        ],
      ),
    );
  }
}

class _BatteryChip extends StatelessWidget {
  const _BatteryChip({required this.level});
  final int level;

  Color get _color {
    if (level > 60) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_std_rounded, size: 13, color: _color),
          const SizedBox(width: 3),
          Text(
            '$level%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
