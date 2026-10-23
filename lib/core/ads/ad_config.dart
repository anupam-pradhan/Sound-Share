import 'package:flutter/foundation.dart';

/// AdMob ad unit IDs.
///
/// Debug/profile builds always use Google's official test units, so tapping
/// ads while developing can never get the AdMob account flagged for invalid
/// traffic. Release builds use the real units below; until they are filled in,
/// release falls back to test ads (which earn nothing).
///
/// The AdMob *App ID* lives separately in android/app/build.gradle.kts
/// (`admobAppId` manifest placeholder).
abstract final class AdConfig {
  // ── Paste your real AdMob ad unit IDs here (AdMob → Apps → Ad units) ──
  static const _realBanner = 'ca-app-pub-8553074995187782/5107080262';
  static const _realInlineBanner = 'ca-app-pub-8553074995187782/3603049021';
  static const _realInterstitial = 'ca-app-pub-8553074995187782/3379687744';
  static const _realAppOpen = 'ca-app-pub-8553074995187782/1735433586';

  // Google's public Android test units
  static const _testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAppOpen = 'ca-app-pub-3940256099942544/9257395921';

  static String get banner => _pick(_realBanner, _testBanner);
  static String get inlineBanner => _pick(_realInlineBanner, _testBanner);
  static String get interstitial => _pick(_realInterstitial, _testInterstitial);
  static String get appOpen => _pick(_realAppOpen, _testAppOpen);

  /// True when a release build would serve real, paying ads.
  static bool get hasRealIds =>
      _realBanner.isNotEmpty &&
      _realInlineBanner.isNotEmpty &&
      _realInterstitial.isNotEmpty &&
      _realAppOpen.isNotEmpty;

  static String _pick(String real, String test) =>
      kReleaseMode && real.isNotEmpty ? real : test;

  // ── Frequency caps (AdMob policy: no surprise or back-to-back full-screen ads) ──

  /// Minimum gap between any two full-screen ads.
  static const fullScreenCooldown = Duration(seconds: 60);

  /// Time the app must spend in the background before an app open ad shows.
  static const appOpenMinBackground = Duration(seconds: 30);

  /// App open ads expire after 4 hours (Google guidance).
  static const appOpenExpiry = Duration(hours: 4);

  /// Longest the splash waits for an app open ad before moving on.
  static const splashAdTimeout = Duration(seconds: 3);
}
