import 'beat_event.dart';

/// Abstract contract for the BeatSync haptic engine.
abstract class HapticEngine {
  /// Checks whether hardware vibration / haptic engine is available.
  Future<bool> isAvailable();

  /// Triggers a test haptic pulse.
  Future<void> test();

  /// Triggers a haptic event according to beat characteristics and strength.
  Future<void> triggerBeat({
    required double strength,
    required BeatType type,
  });

  /// Stops any active vibration immediately.
  Future<void> stop();

  /// Sets global haptic intensity multiplier.
  Future<void> setIntensity(double value);
}
