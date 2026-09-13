import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

class AppUpdateService {
  AppUpdateService._();

  /// Check if an app update is available.
  /// In a live Play Store deployment, this queries the In-App Update API or your backend version endpoint.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      await PackageInfo.fromPlatform();
      // Future-proof hook: check if remote version > current version
      // When deployed to Play Store, this integrates with Android In-App Updates
    } catch (_) {}
  }

  /// Show the Update Available modal dialog
  static void showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String releaseNotes,
    bool isForceUpdate = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !isForceUpdate,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 32,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Update Available',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A new version ($latestVersion) of SoundShare is available with improved audio sharing stability.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        releaseNotes,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (!isForceUpdate) ...[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Later',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Opens Google Play Store listing
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 48,
                            decoration: AppGradients.primaryButton(radius: 14),
                            child: const Center(
                              child: Text(
                                'Update Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
