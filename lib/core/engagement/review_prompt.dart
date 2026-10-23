import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a Play Store rating at a moment of success: after the user's 3rd
/// sharing session of 2+ minutes, then again every 10 such sessions. Google
/// additionally rate-limits the native dialog, so it can never nag.
abstract final class ReviewPrompt {
  static const _keySessions = 'review_good_sessions';
  static const _minSession = Duration(minutes: 2);
  static const _firstAsk = 3;
  static const _askEvery = 10;

  static Future<void> onShareFinished(Duration session) async {
    if (session < _minSession) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_keySessions) ?? 0) + 1;
      await prefs.setInt(_keySessions, count);

      final due = count == _firstAsk ||
          (count > _firstAsk && (count - _firstAsk) % _askEvery == 0);
      if (!due) return;

      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } on Exception catch (e) {
      debugPrint('ReviewPrompt failed: $e');
    }
  }
}
