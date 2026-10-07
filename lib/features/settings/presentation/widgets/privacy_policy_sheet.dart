import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/app_sheet.dart';

/// In-app summary of the SoundShare privacy policy.
class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static void show(BuildContext context) {
    AppSheet.show<void>(context, (_) => const PrivacyPolicySheet());
  }

  static const _sections = [
    (
      icon: Icons.person_off_outlined,
      title: 'No accounts, no ads',
      body: 'SoundShare has no sign-in and no advertising. We do not sell '
          'or share your information.',
    ),
    (
      icon: Icons.insights_outlined,
      title: 'Anonymous usage analytics',
      body: 'We use Google Firebase Analytics to understand how the app is '
          'used, such as app opens, screens viewed, device model and Android '
          'version. It never includes your audio, contacts or device names.',
    ),
    (
      icon: Icons.graphic_eq_rounded,
      title: 'Audio capture stays on your devices',
      body: 'When you start sharing, Android asks you to allow audio capture. '
          'Audio from other apps is processed in memory and sent only to your '
          'headphones or to people on your Wi-Fi who open your share link. '
          'It is never recorded, stored or uploaded.',
    ),
    (
      icon: Icons.mic_none_rounded,
      title: 'Why “record audio” is requested',
      body: 'Android requires this permission to capture playback audio. '
          'SoundShare never uses your microphone.',
    ),
    (
      icon: Icons.wifi_rounded,
      title: 'Wi-Fi sharing is local only',
      body: 'Your share link works only on your local Wi-Fi or hotspot and '
          'only while sharing is on. Anyone on that network with the link can listen.',
    ),
    (
      icon: Icons.bluetooth_rounded,
      title: 'Bluetooth and nearby devices',
      body:
          'Used only to find and connect your headphones. Device names stay on your phone.',
    ),
    (
      icon: Icons.notifications_none_rounded,
      title: 'Notifications',
      body:
          'A notification is shown while sharing so audio keeps playing with the screen off.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AppSheet(
      title: 'Privacy',
      subtitle: 'How SoundShare handles your data',
      icon: Icons.shield_outlined,
      footer: PrimaryButton(
        label: 'Got it',
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, size: 19, color: AppColors.purple),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.body,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Published by Quick Media Solution. Questions? Contact us from the '
            'SoundShare page on Google Play.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
