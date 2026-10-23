import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Owns AdMob for the whole app: consent, SDK start-up, interstitials and
/// app open ads, plus the rules that keep full-screen ads policy-safe.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  final Completer<bool> _ready = Completer<bool>();

  /// Completes with true once ads may be requested (consent gathered, SDK up).
  Future<bool> get ready => _ready.future;
  bool get isReady => _ready.isCompleted;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;

  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  bool _appOpenLoading = false;

  bool _showingFullScreen = false;
  DateTime? _lastFullScreenAt;
  DateTime? _backgroundedAt;
  bool _suppressNextAppOpen = false;
  bool _sharingActive = false;
  AppLifecycleListener? _lifecycle;

  // ──────────────────────────────────────────────
  // Start-up
  // ──────────────────────────────────────────────

  /// Gathers consent (UMP), starts the SDK and preloads full-screen ads.
  /// Safe to call more than once.
  Future<bool> initialize() async {
    if (_ready.isCompleted) return _ready.future;
    if (_initStarted) return _ready.future;
    _initStarted = true;

    var canRequest = false;
    try {
      await _gatherConsent();
      canRequest = await ConsentInformation.instance.canRequestAds();
    } on Exception catch (e) {
      debugPrint('AdService: consent failed: $e');
    }
    if (canRequest) {
      try {
        await MobileAds.instance.initialize();
        _loadInterstitial();
        _loadAppOpen();
      } on Exception catch (e) {
        debugPrint('AdService: SDK init failed: $e');
        canRequest = false;
      }
    }
    _lifecycle ??= AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _ready.complete(canRequest);
    return canRequest;
  }

  bool _initStarted = false;

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('AdService: consent form: ${error.message}');
          }
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        debugPrint('AdService: consent update: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  /// Whether Settings must offer "Ad privacy options" (EU/UK users).
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } on Exception {
      return false;
    }
  }

  Future<void> showPrivacyOptions() =>
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint('AdService: privacy options: ${error.message}');
        }
      });

  // ──────────────────────────────────────────────
  // Rules shared by all full-screen ads
  // ──────────────────────────────────────────────

  /// While audio is shared, full-screen ads would cover the controls and
  /// steal audio focus, so none are shown.
  void setSharingActive(bool active) => _sharingActive = active;

  /// Call before opening a system screen (Bluetooth settings, capture
  /// consent…), so coming back from it never triggers an app open ad.
  void suppressNextAppOpen() => _suppressNextAppOpen = true;

  bool get _cooldownOver {
    final last = _lastFullScreenAt;
    return last == null ||
        DateTime.now().difference(last) >= AdConfig.fullScreenCooldown;
  }

  bool get _canShowFullScreen =>
      isReady && !_showingFullScreen && !_sharingActive && _cooldownOver;

  void _markShown() {
    _showingFullScreen = true;
    _lastFullScreenAt = DateTime.now();
  }

  void _markDismissed() => _showingFullScreen = false;

  // ──────────────────────────────────────────────
  // Interstitial
  // ──────────────────────────────────────────────

  void _loadInterstitial() {
    if (_interstitial != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          debugPrint('AdService: interstitial failed: ${error.message}');
        },
      ),
    );
  }

  /// Shows an interstitial at a natural break, if one is loaded and the
  /// frequency cap allows it. Returns whether an ad was shown.
  bool showInterstitial() {
    final ad = _interstitial;
    if (ad == null || !_canShowFullScreen) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _markShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _markDismissed();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _markDismissed();
        _loadInterstitial();
      },
    );
    ad.show();
    return true;
  }

  // ──────────────────────────────────────────────
  // App open
  // ──────────────────────────────────────────────

  bool get _appOpenFresh {
    final at = _appOpenLoadedAt;
    return _appOpen != null &&
        at != null &&
        DateTime.now().difference(at) < AdConfig.appOpenExpiry;
  }

  void _loadAppOpen() {
    if (_appOpenFresh || _appOpenLoading) return;
    _appOpen?.dispose();
    _appOpen = null;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: AdConfig.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _appOpenLoading = false;
          debugPrint('AdService: app open failed: ${error.message}');
        },
      ),
    );
  }

  /// Splash: waits briefly for an app open ad and shows it. Resolves when the
  /// ad is dismissed (or immediately when none is available in time).
  Future<void> showAppOpenOnLaunch() async {
    final canRequest = await ready.timeout(
      AdConfig.splashAdTimeout,
      onTimeout: () => false,
    );
    if (!canRequest) return;
    final deadline = DateTime.now().add(AdConfig.splashAdTimeout);
    while (!_appOpenFresh && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    final dismissed = Completer<void>();
    if (!_showAppOpen(onClosed: () => dismissed.complete())) return;
    await dismissed.future;
  }

  bool _showAppOpen({VoidCallback? onClosed}) {
    if (!_appOpenFresh || !_canShowFullScreen) {
      _loadAppOpen();
      return false;
    }
    final ad = _appOpen;
    if (ad == null) return false;
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _markShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _markDismissed();
        _loadAppOpen();
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _markDismissed();
        _loadAppOpen();
        onClosed?.call();
      },
    );
    ad.show();
    return true;
  }

  void _onHide() {
    // A full-screen ad itself hides the app; that must not count.
    if (!_showingFullScreen) _backgroundedAt = DateTime.now();
  }

  void _onShow() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (_suppressNextAppOpen) {
      _suppressNextAppOpen = false;
      return;
    }
    if (since == null ||
        DateTime.now().difference(since) < AdConfig.appOpenMinBackground) {
      return;
    }
    _showAppOpen();
  }
}
