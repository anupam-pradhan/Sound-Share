import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/features/beatsync/domain/beat_event.dart';

void main() {
  group('BeatSync Models & Parsing Tests', () {
    test('Parses BeatEvent from map with various beat types', () {
      final map = {
        'timestamp': 1700000000000,
        'type': 'kick',
        'strength': 0.85,
        'energy': 0.72,
      };

      final event = BeatEvent.fromMap(map);
      expect(event.type, BeatType.kick);
      expect(event.strength, 0.85);
      expect(event.energy, 0.72);
      expect(event.timestamp.millisecondsSinceEpoch, 1700000000000);
    });

    test('Parses drop and snare BeatEvents accurately', () {
      final dropEvent = BeatEvent.fromMap({
        'type': 'drop',
        'strength': 1.0,
        'energy': 0.95,
      });
      expect(dropEvent.type, BeatType.drop);
      expect(dropEvent.strength, 1.0);

      final snareEvent = BeatEvent.fromMap({
        'type': 'snare',
        'strength': 0.6,
        'energy': 0.4,
      });
      expect(snareEvent.type, BeatType.snare);
    });

    test('Clamps strength and energy between 0.0 and 1.0', () {
      final event = BeatEvent.fromMap({
        'type': 'kick',
        'strength': 2.5,
        'energy': -0.5,
      });
      expect(event.strength, 1.0);
      expect(event.energy, 0.0);
    });

    test('HapticCapabilities fromMap handles fallback values', () {
      final caps = HapticCapabilities.fromMap({
        'available': true,
        'supportsAmplitude': true,
        'supportsAdvancedEffects': false,
        'androidVersion': 33,
      });

      expect(caps.available, true);
      expect(caps.supportsAmplitude, true);
      expect(caps.supportsAdvancedEffects, false);
      expect(caps.androidVersion, 33);
    });

    test('BeatSyncSettings copyWith updates values correctly', () {
      const initial = BeatSyncSettings();
      expect(initial.enabled, false);
      expect(initial.intensity, 1.0);
      expect(initial.sensitivity, 1.0);
      expect(initial.bassBoost, 1.3);

      final updated = initial.copyWith(
        enabled: true,
        intensity: 1.5,
        bassBoost: 1.6,
      );

      expect(updated.enabled, true);
      expect(updated.intensity, 1.5);
      expect(updated.sensitivity, 1.0);
      expect(updated.bassBoost, 1.6);
    });
  });
}
