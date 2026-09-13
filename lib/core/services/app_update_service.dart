import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';

/// App update service using the official Google Play Core In-App Updates API.
class AppUpdateService {
  AppUpdateService._();

  /// Check if an app update is available via Google Play Core API.
  /// Shows a flexible update flow if available, or falls back to
  /// showing a custom dialog for force updates.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Check if immediate update is allowed (force update)
        if (updateInfo.immediateUpdateAllowed) {
          // Critical update — blocks the app until updated
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Non-critical update — downloads in background
          await InAppUpdate.startFlexibleUpdate();
          // Once downloaded, prompt to install
          await InAppUpdate.completeFlexibleUpdate();
        } else {
          // Update available but neither mode allowed — show custom dialog
          final info = await PackageInfo.fromPlatform();
          if (context.mounted) {
            showUpdateDialog(
              context,
              latestVersion: 'New Version',
              releaseNotes:
                  'A new version of SoundShare is available with improved audio sharing.',
              currentVersion: info.version,
            );
          }
        }
      }
    } catch (_) {
      // In-app update not supported (e.g., debug builds, sideloaded APK)
      // Silently fail — this is expected during development
    }
  }

  /// Show the Update Available modal dialog (fallback for when Play Core
  /// in-app update is not available).
  static void showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String releaseNotes,
    String? currentVersion,
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
                          onTap: () async {
                            Navigator.of(context).pop();
                            // Try Play Core immediate update as fallback
                            try {
                              await InAppUpdate.performImmediateUpdate();
                            } catch (_) {}
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
