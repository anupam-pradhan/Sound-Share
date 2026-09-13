import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';

/// Modal dialog allowing users to rate SoundShare on the Google Play Store.
class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RateAppDialog(),
    );
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  int _selectedStars = 5;
  bool _submitted = false;

  Future<void> _submitRating() async {
    AppHaptics.light();
    setState(() => _submitted = true);

    // Open Play Store for rating
    try {
      const MethodChannel('com.soundshare/audio').invokeMethod('openPlayStore');
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Star Icon badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 34,
                color: Colors.amber,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _submitted ? 'Thank You!' : 'Enjoying SoundShare?',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              _submitted
                  ? 'Opening Google Play Store to complete your review...'
                  : 'Tap the stars to rate your audio sharing and BeatSync experience on Google Play.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: 20),

            if (!_submitted) ...[
              // Interactive Star Rating Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= _selectedStars;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      setState(() => _selectedStars = starIndex);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: isFilled ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.star_rounded,
                          size: 36,
                          color: isFilled ? Colors.amber : AppColors.divider,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
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
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitRating,
                      child: Container(
                        height: 48,
                        decoration: AppGradients.primaryButton(radius: 14),
                        child: const Center(
                          child: Text(
                            'Rate on Play Store',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 38,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
