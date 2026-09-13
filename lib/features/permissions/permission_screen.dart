import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.notification,
        Permission.locationWhenInUse,
      ].request();
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
        context.go('/share');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Icon illustration
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF26243A)
                      : AppColors.purpleLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_audio_rounded,
                  size: 44,
                  color: AppColors.purple,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Allow Permissions',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'SoundShare needs Bluetooth and notification access to discover nearby devices and stream synchronized audio.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // Permission items
              const _PermissionTile(
                icon: Icons.bluetooth_searching_rounded,
                title: 'Nearby Bluetooth Devices',
                subtitle:
                    'Discover and connect to additional headphones and speakers',
              ),

              const SizedBox(height: 16),

              const _PermissionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Foreground Notifications',
                subtitle:
                    'Keep audio stream alive in background and show session controls',
              ),

              const Spacer(flex: 2),

              // Continue button
              GestureDetector(
                onTap: _isRequesting ? null : _requestPermissions,
                child: Container(
                  height: 56,
                  decoration: AppGradients.primaryButton(radius: 18),
                  child: Center(
                    child: _isRequesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Grant Permissions',
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Skip / Not now
              TextButton(
                onPressed: () => context.go('/share'),
                child: Text(
                  'Set up later',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.purple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
