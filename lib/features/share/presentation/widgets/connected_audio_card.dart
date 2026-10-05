import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/animated_widgets.dart';
import 'package:soundshare/core/widgets/bluetooth_device_icon.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';

/// Card showing the user's currently active audio source device.
class ConnectedAudioCard extends StatelessWidget {
  const ConnectedAudioCard({
    super.key,
    this.deviceType = BluetoothDeviceType.phone,
    this.deviceName,
    this.batteryLevel,
    this.isConnected = false,
    this.isSharing = false,
    this.connectedDevicesCount = 0,
  });

  final BluetoothDeviceType deviceType;
  final String? deviceName;
  final int? batteryLevel;
  final bool isConnected;
  final bool isSharing;
  final int connectedDevicesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String statusLabel;
    final Color statusColor;
    if (!isConnected) {
      statusLabel = 'Bluetooth Off';
      statusColor = AppColors.textMuted;
    } else if (isSharing) {
      statusLabel = 'Live Sharing Active';
      statusColor = AppColors.success;
    } else if (connectedDevicesCount >= 2) {
      statusLabel = 'Dual Mode Ready';
      statusColor = AppColors.purple;
    } else if (connectedDevicesCount == 1) {
      statusLabel = '1 Device Connected';
      statusColor = AppColors.blue;
    } else {
      statusLabel = 'This Phone • Ready';
      statusColor = AppColors.success;
    }

    final String descriptionLabel;
    if (!isConnected) {
      descriptionLabel = 'Turn on Bluetooth to find audio devices';
    } else if (isSharing) {
      descriptionLabel = connectedDevicesCount >= 2
          ? 'Streaming synchronized audio to 2 headphones'
          : 'Streaming audio to $connectedDevicesCount connected device';
    } else if (connectedDevicesCount >= 2) {
      descriptionLabel = 'Ready to stream to both headphones simultaneously';
    } else if (connectedDevicesCount == 1) {
      descriptionLabel = 'Ready to stream (Connect 2nd headphone for dual share)';
    } else {
      descriptionLabel = 'Connect Bluetooth headphones below to share audio';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSharing
              ? AppColors.purple.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
          width: isSharing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSharing
                ? AppColors.purple.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.cardShadow),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device icon (Mobile Phone)
          BluetoothDeviceIcon(
            type: deviceType,
            size: 28,
            isConnected: isConnected,
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Audio Source', style: AppTextStyles.headingSmall),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedStatusBadge(
                            isActive: isConnected,
                            activeColor: statusColor,
                            size: 6,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deviceName ?? 'This Phone (Media Audio)',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descriptionLabel,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
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
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
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
