import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/motion/motion.dart';
import 'package:soundshare/core/widgets/surface.dart';

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
        Permission.microphone,
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Entrance(child: _OnboardingHero()),
              const SizedBox(height: 28),
              Entrance(
                index: 1,
                child: Text(
                  'A few permissions to get started',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Entrance(
                index: 2,
                child: Text(
                  'Used only to share your audio. Your audio is never recorded or uploaded.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              const Entrance(
                index: 3,
                child: Surface(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _PermissionTile(
                        icon: Icons.bluetooth_rounded,
                        title: 'Nearby devices',
                        subtitle: 'Find and connect your headphones',
                      ),
                      _TileDivider(),
                      _PermissionTile(
                        icon: Icons.graphic_eq_rounded,
                        title: 'Audio capture',
                        subtitle: 'Share the music playing on this phone',
                      ),
                      _TileDivider(),
                      _PermissionTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Keep sharing running with screen off',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Entrance(
                index: 4,
                offset: 24,
                child: PressableScale(
                  onTap: _isRequesting ? null : _requestPermissions,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: AppGradients.primaryButton(radius: 18),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _isRequesting ? null : _requestPermissions,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: Motion.fast,
                              child: _isRequesting
                                  ? const SizedBox(
                                      key: ValueKey('busy'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Continue',
                                      key: const ValueKey('label'),
                                      style: AppTextStyles.buttonLarge
                                          .copyWith(color: Colors.white),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/share'),
                  child: Text(
                    'Not now',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand illustration: phone sending sound to two headphones.
class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final size in [180.0, 130.0])
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18), width: 1.5),
              ),
            ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroBubble(icon: Icons.headphones_rounded, size: 52),
              SizedBox(width: 18),
              _HeroBubble(
                  icon: Icons.smartphone_rounded, size: 76, solid: true),
              SizedBox(width: 18),
              _HeroBubble(icon: Icons.headphones_rounded, size: 52),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  const _HeroBubble(
      {required this.icon, required this.size, this.solid = false});
  final IconData icon;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Icon(icon,
          size: size * 0.46, color: solid ? AppColors.purple : Colors.white),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 72, color: Surface.borderColor(context));
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: AppColors.purple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
