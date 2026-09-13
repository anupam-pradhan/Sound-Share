import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/beat_event.dart';
import '../domain/haptic_engine.dart';

/// Concrete implementation of BeatSync and HapticEngine over Android MethodChannel & EventChannel.
class AndroidBeatSyncService implements HapticEngine {
  static const _methodChannel = MethodChannel('com.soundshare/beatsync');
  static const _eventChannel = EventChannel('com.soundshare/beatsync_events');

  Stream<BeatEvent>? _beatEventStream;
  HapticCapabilities? _cachedCapabilities;

  /// Stream of real-time beat events from native audio analysis.
  Stream<BeatEvent> get beatEvents {
    _beatEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          if (event is Map) {
            return BeatEvent.fromMap(event);
          }
          return null;
        })
        .where((event) => event != null)
        .cast<BeatEvent>();
    return _beatEventStream!;
  }

  /// Query native vibration and OS capabilities.
  Future<HapticCapabilities> getCapabilities() async {
    if (_cachedCapabilities != null) return _cachedCapabilities!;
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>('getCapabilities');
      if (result != null) {
        _cachedCapabilities = HapticCapabilities.fromMap(result);
        return _cachedCapabilities!;
      }
    } catch (_) {}
    _cachedCapabilities = const HapticCapabilities();
    return _cachedCapabilities!;
  }

  /// Start real-time audio analysis and haptic generation.
  Future<bool> startBeatSync() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startBeatSync');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Stop audio analysis and haptics.
  Future<void> stopBeatSync() async {
    try {
      await _methodChannel.invokeMethod('stopBeatSync');
    } catch (_) {}
  }

  /// Push updated intensity, sensitivity, and bass settings to native engine.
  Future<void> updateSettings(BeatSyncSettings settings) async {
    try {
      await _methodChannel.invokeMethod('updateSettings', {
        'intensity': settings.intensity,
        'sensitivity': settings.sensitivity,
        'bass': settings.bassBoost,
      });
    } catch (_) {}
  }

  @override
  Future<bool> isAvailable() async {
    final caps = await getCapabilities();
    return caps.available;
  }

  @override
  Future<void> test() async {
    try {
      await _methodChannel.invokeMethod('testPulse');
    } catch (_) {}
  }

  @override
  Future<void> triggerBeat({
    required double strength,
    required BeatType type,
  }) async {
    // Handled directly inside native engine for ultra-low latency;
    // can also trigger ad-hoc pulse if needed.
  }

  @override
  Future<void> stop() async {
    await stopBeatSync();
  }

  @override
  Future<void> setIntensity(double value) async {
    // Updated via updateSettings
  }

  void dispose() {
    stopBeatSync();
  }
}
