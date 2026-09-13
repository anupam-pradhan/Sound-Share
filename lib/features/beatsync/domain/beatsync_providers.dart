import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/android_beatsync_service.dart';
import 'beat_event.dart';

// ──────────────────────────────────────────────
// Service Provider
// ──────────────────────────────────────────────

final beatSyncServiceProvider = Provider<AndroidBeatSyncService>((ref) {
  final service = AndroidBeatSyncService();
  ref.onDispose(service.dispose);
  return service;
});

// ──────────────────────────────────────────────
// Haptic Capabilities Provider
// ──────────────────────────────────────────────

final hapticCapabilitiesProvider =
    FutureProvider<HapticCapabilities>((ref) async {
  final service = ref.watch(beatSyncServiceProvider);
  return service.getCapabilities();
});

// ──────────────────────────────────────────────
// Beat Events Stream Provider
// ──────────────────────────────────────────────

final beatEventsStreamProvider = StreamProvider<BeatEvent>((ref) {
  final service = ref.watch(beatSyncServiceProvider);
  return service.beatEvents;
});

// ──────────────────────────────────────────────
// BeatSync Settings Notifier
// ──────────────────────────────────────────────

final beatSyncSettingsProvider =
    StateNotifierProvider<BeatSyncSettingsNotifier, BeatSyncSettings>((ref) {
  return BeatSyncSettingsNotifier(ref);
});

class BeatSyncSettingsNotifier extends StateNotifier<BeatSyncSettings> {
  BeatSyncSettingsNotifier(this._ref) : super(const BeatSyncSettings()) {
    _loadFromPrefs();
  }

  final Ref _ref;
  static const _kPrefEnabled = 'beatsync_enabled';
  static const _kPrefIntensity = 'beatsync_intensity';
  static const _kPrefSensitivity = 'beatsync_sensitivity';
  static const _kPrefBassBoost = 'beatsync_bass_boost';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kPrefEnabled) ?? false;
      final intensity = prefs.getDouble(_kPrefIntensity) ?? 1.0;
      final sensitivity = prefs.getDouble(_kPrefSensitivity) ?? 1.0;
      final bassBoost = prefs.getDouble(_kPrefBassBoost) ?? 1.3;

      state = BeatSyncSettings(
        enabled: enabled,
        intensity: intensity,
        sensitivity: sensitivity,
        bassBoost: bassBoost,
      );

      final service = _ref.read(beatSyncServiceProvider);
      await service.updateSettings(state);

      if (enabled) {
        _ref.read(beatSyncStatusProvider.notifier).startBeatSync();
      }
    } catch (_) {}
  }

  Future<void> toggleEnabled() async {
    final next = !state.enabled;
    state = state.copyWith(enabled: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, next);

    if (next) {
      await _ref.read(beatSyncStatusProvider.notifier).startBeatSync();
    } else {
      await _ref.read(beatSyncStatusProvider.notifier).stopBeatSync();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.enabled == enabled) return;
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, enabled);

    if (enabled) {
      await _ref.read(beatSyncStatusProvider.notifier).startBeatSync();
    } else {
      await _ref.read(beatSyncStatusProvider.notifier).stopBeatSync();
    }
  }

  Future<void> setIntensity(double intensity) async {
    state = state.copyWith(intensity: intensity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefIntensity, intensity);
    await _ref.read(beatSyncServiceProvider).updateSettings(state);
  }

  Future<void> setSensitivity(double sensitivity) async {
    state = state.copyWith(sensitivity: sensitivity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefSensitivity, sensitivity);
    await _ref.read(beatSyncServiceProvider).updateSettings(state);
  }

  Future<void> setBassBoost(double bassBoost) async {
    state = state.copyWith(bassBoost: bassBoost);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefBassBoost, bassBoost);
    await _ref.read(beatSyncServiceProvider).updateSettings(state);
  }
}

// ──────────────────────────────────────────────
// BeatSync Operational Status Notifier
// ──────────────────────────────────────────────

final beatSyncStatusProvider =
    StateNotifierProvider<BeatSyncStatusNotifier, BeatSyncStatus>((ref) {
  return BeatSyncStatusNotifier(ref);
});

class BeatSyncStatusNotifier extends StateNotifier<BeatSyncStatus> {
  BeatSyncStatusNotifier(this._ref) : super(BeatSyncStatus.off) {
    _listenToBeatEvents();
  }

  final Ref _ref;
  StreamSubscription<BeatEvent>? _eventSub;
  Timer? _inactivityTimer;

  void _listenToBeatEvents() {
    final service = _ref.read(beatSyncServiceProvider);
    _eventSub = service.beatEvents.listen((_) {
      if (state == BeatSyncStatus.analyzing || state == BeatSyncStatus.ready) {
        state = BeatSyncStatus.active;
      }
      _resetInactivityTimer();
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 4), () {
      if (state == BeatSyncStatus.active) {
        state = BeatSyncStatus.analyzing;
      }
    });
  }

  Future<void> startBeatSync() async {
    state = BeatSyncStatus.analyzing;
    final service = _ref.read(beatSyncServiceProvider);
    final caps = await service.getCapabilities();

    if (!caps.available) {
      state = BeatSyncStatus.unavailable;
      return;
    }

    final success = await service.startBeatSync();
    if (!success) {
      state = BeatSyncStatus.unavailable;
    }
  }

  Future<void> stopBeatSync() async {
    _inactivityTimer?.cancel();
    state = BeatSyncStatus.off;
    final service = _ref.read(beatSyncServiceProvider);
    await service.stopBeatSync();
  }

  Future<void> testPulse() async {
    final service = _ref.read(beatSyncServiceProvider);
    await service.test();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }
}
