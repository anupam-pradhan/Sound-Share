import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/core/widgets/app_sheet.dart';
import 'package:soundshare/core/widgets/surface.dart';

/// About SoundShare and the company behind it.
class AboutSoundShareSheet extends StatelessWidget {
  const AboutSoundShareSheet({super.key, required this.version});

  final String version;

  static void show(BuildContext context, {required String version}) {
    AppSheet.show<void>(context, (_) => AboutSoundShareSheet(version: version));
  }

  static const _features = [
    (
      icon: Icons.headphones_rounded,
      title: 'Listen together',
      body: 'Share what you are playing with headphones and friends nearby.',
    ),
    (
      icon: Icons.wifi_rounded,
      title: 'Works over Wi-Fi',
      body: 'Friends join from a link on your Wi-Fi or hotspot. No app needed.',
    ),
    (
      icon: Icons.shield_outlined,
      title: 'Private by design',
      body: 'No accounts, no ads. Your audio is never recorded or uploaded.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AppSheet(
      title: 'About',
      footer: PrimaryButton(
        label: 'Done',
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Surface.borderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
          ),
          const SizedBox(height: 14),
          Text(
            'SoundShare',
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version $version  •  Quick Media Solution',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 22),
          Surface(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < _features.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 70,
                      color: Surface.borderColor(context),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            _features[i].icon,
                            size: 20,
                            color: AppColors.purple,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _features[i].title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _features[i].body,
                                style: AppTextStyles.bodySmall
                                    .copyWith(fontSize: 12.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Quick Media Solution. All rights reserved.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
