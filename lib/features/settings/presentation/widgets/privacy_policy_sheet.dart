import 'package:flutter/material.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

/// Modal bottom sheet displaying the SoundShare Privacy Policy.
class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Privacy Policy', style: AppTextStyles.headingMedium),
                    Text('SoundShare • 100% Privacy Focused',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: AppColors.divider),

          // Scrollable policy content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _policySection(
                    title: '1. No Data Collection',
                    content:
                        'SoundShare does not collect, track, or share any personal identifying information (PII). We do not require accounts, logins, or cloud synchronization.',
                  ),
                  _policySection(
                    title: '2. Bluetooth Permissions',
                    content:
                        'Bluetooth permissions (BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH_ADVERTISE) are used exclusively on your device to locate, connect, and stream audio to nearby audio receivers.',
                  ),
                  _policySection(
                    title: '3. Audio Processing (BeatSync)',
                    content:
                        'When BeatSync is active, audio frequencies are analyzed entirely in volatile device memory (RAM) in real time to trigger synchronized vibration pulses. No audio is ever recorded, stored, or transmitted over the internet.',
                  ),
                  _policySection(
                    title: '4. Foreground Service & Notifications',
                    content:
                        'Foreground media playback services are used to keep your audio stream and BeatSync haptics uninterrupted when switching applications or locking your screen.',
                  ),
                  _policySection(
                    title: '5. Zero Advertisements',
                    content:
                        'SoundShare contains zero third-party advertisement SDKs, analytical trackers, or data monetization libraries.',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Accept / Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 50,
                decoration: AppGradients.primaryButton(radius: 16),
                child: const Center(
                  child: Text(
                    'I Understand',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.purple,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
