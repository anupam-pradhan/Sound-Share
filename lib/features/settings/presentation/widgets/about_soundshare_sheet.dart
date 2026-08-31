import 'package:flutter/material.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

/// Interactive About Modal Sheet detailing the app's mission by solo developer Anupam Pradhan.
class AboutSoundShareSheet extends StatelessWidget {
  const AboutSoundShareSheet({super.key, required this.version});

  final String version;

  static void show(BuildContext context, {required String version}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AboutSoundShareSheet(version: version),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Logo with gentle gradient border
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  AppAssets.logo,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Title & Version
            Text('SoundShare', style: AppTextStyles.headingLarge),
            const SizedBox(height: 2),
            Text(
              version.isNotEmpty ? 'Version $version' : 'Version 1.0.0',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),

            const SizedBox(height: 20),

            // Creator & Mission Highlight Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Crafted by Anupam Pradhan',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Built with passion as an independent solo project. SoundShare was created with a clear promise: 100% free, zero ads, and no recurring subscriptions.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Feature Highlights
            const _FeatureRow(
              icon: Icons.block_rounded,
              title: 'No Ads & No Paywalls',
              description: 'Pure listening experience with zero interruptions or subscriptions.',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              icon: Icons.graphic_eq_rounded,
              title: 'Crystal Clear Dual Audio',
              description: 'Share your favorite songs and podcasts across two devices synchronously.',
            ),
            const SizedBox(height: 12),
            const _FeatureRow(
              icon: Icons.shield_outlined,
              title: 'Privacy Focused',
              description: 'No telemetry or audio recording is ever stored or transmitted.',
            ),

            const SizedBox(height: 26),

            // Close button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 50,
                decoration: AppGradients.primaryButton(radius: 16),
                child: const Center(
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.purple, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
