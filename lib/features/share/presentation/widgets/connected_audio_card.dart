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
  });

  final BluetoothDeviceType deviceType;
  final String? deviceName;
  final int? batteryLevel;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.cardShadow,
            blurRadius: 12,
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
                Text('Audio Source', style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AnimatedStatusBadge(isActive: isConnected, size: 7),
                    const SizedBox(width: 5),
                    Text(
                      isConnected ? 'This Phone • Ready' : 'Not Connected',
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
                  deviceName ?? 'This Phone (Media Audio)',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected
                      ? 'Ready to share audio stream'
                      : 'Turn on Bluetooth to share audio',
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
