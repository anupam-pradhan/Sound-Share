import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Firebase Analytics for the funnel that matters: install → permissions →
/// first share → repeat shares. Every call is fire-and-forget and swallows
/// errors, so analytics can never break the app.
///
/// AdMob revenue (ad_impression with value) is reported automatically once the
/// AdMob app is linked to this Firebase project in the AdMob console.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  /// Navigator observers for GoRouter so top-level routes log screen_view.
  List<NavigatorObserver> get observers {
    final analytics = _analytics;
    return analytics == null
        ? const []
        : [FirebaseAnalyticsObserver(analytics: analytics)];
  }

  /// Called after Firebase.initializeApp() succeeded.
  void attach() => _analytics = FirebaseAnalytics.instance;

  void _log(String name, [Map<String, Object>? params]) {
    final analytics = _analytics;
    if (analytics == null) return;
    analytics.logEvent(name: name, parameters: params).catchError((Object e) {
      debugPrint('Analytics $name failed: $e');
    });
  }

  // ── Screens ──

  void screen(String name) {
    final analytics = _analytics;
    if (analytics == null) return;
    analytics.logScreenView(screenName: name).catchError((Object e) {
      debugPrint('Analytics screen $name failed: $e');
    });
  }

  // ── Onboarding ──

  void permissionsResult({required bool granted}) =>
      _log('permissions_result', {'granted': granted ? 1 : 0});

  // ── Core feature ──

  void shareStarted({required String mode, required int headphones}) =>
      _log('share_start', {'mode': mode, 'headphones': headphones});

  void shareStopped({required String mode, required Duration duration}) =>
      _log('share_stop', {'mode': mode, 'duration_s': duration.inSeconds});

  void modeSelected(String mode) {
    _log('mode_select', {'mode': mode});
    _analytics?.setUserProperty(name: 'sharing_mode', value: mode);
  }

  void deviceConnected({required String type}) =>
      _log('device_connect', {'type': type});

  // ── Engagement ──

  void rateDialogOpened() => _log('rate_dialog_open');
  void invitePeersOpened() => _log('invite_open');
}
