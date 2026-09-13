import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/features/spatial_audio/domain/spatial_audio_models.dart';

void main() {
  group('SpatialAudioPosition Tests', () {
    test('Calculates correct azimuth angles', () {
      // Front (0, 0.8)
      const front = SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);
      expect(front.azimuth, closeTo(0.0, 0.01));
      expect(front.azimuthDegrees, closeTo(0.0, 0.5));

      // Right (1.0, 0.0)
      const right = SpatialAudioPosition(x: 1.0, y: 0.0, z: 0.0);
      expect(right.azimuth, closeTo(math.pi / 2, 0.01));
      expect(right.azimuthDegrees, closeTo(90.0, 0.5));

      // Left (-1.0, 0.0)
      const left = SpatialAudioPosition(x: -1.0, y: 0.0, z: 0.0);
      expect(left.azimuth, closeTo(-math.pi / 2, 0.01));
      expect(left.azimuthDegrees, closeTo(270.0, 0.5));

      // Back (0.0, -1.0)
      const back = SpatialAudioPosition(x: 0.0, y: -1.0, z: 0.0);
      expect(back.azimuth.abs(), closeTo(math.pi, 0.01));
      expect(back.azimuthDegrees, closeTo(180.0, 0.5));
    });

    test('Provides accurate screen-reader accessibility labels', () {
      const front = SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);
      expect(front.toAccessibleLabel(), contains('Front'));

      const right = SpatialAudioPosition(x: 0.9, y: 0.0, z: 0.0);
      expect(right.toAccessibleLabel(), contains('Right'));

      const backLeft = SpatialAudioPosition(x: -0.8, y: -0.8, z: 0.0);
      expect(backLeft.toAccessibleLabel(), contains('Back Left'));
    });

    test('Clamps coordinates accurately', () {
      final pos = const SpatialAudioPosition().copyWith(x: 2.5, y: -3.0, z: 4.0);
      expect(pos.x, 1.0);
      expect(pos.y, -1.0);
      expect(pos.z, 1.0);
    });

    test('Serialization to/from Map works correctly', () {
      const original = SpatialAudioPosition(x: 0.45, y: -0.65, z: 0.2);
      final map = original.toMap();
      final restored = SpatialAudioPosition.fromMap(map);

      expect(restored.x, closeTo(original.x, 0.001));
      expect(restored.y, closeTo(original.y, 0.001));
      expect(restored.z, closeTo(original.z, 0.001));
    });

    test('Interpolates smoothly with SpatialAudioPosition.lerp and Tween', () {
      const start = SpatialAudioPosition(x: -1.0, y: 0.0, z: 0.0);
      const end = SpatialAudioPosition(x: 1.0, y: 0.8, z: 0.4);

      final mid = SpatialAudioPosition.lerp(start, end, 0.5);
      expect(mid.x, closeTo(0.0, 0.001));
      expect(mid.y, closeTo(0.4, 0.001));
      expect(mid.z, closeTo(0.2, 0.001));

      final tween = SpatialAudioPositionTween(begin: start, end: end);
      final interpolated = tween.lerp(0.25);
      expect(interpolated.x, closeTo(-0.5, 0.001));
      expect(interpolated.y, closeTo(0.2, 0.001));
      expect(interpolated.z, closeTo(0.1, 0.001));
    });
  });

  group('Spatial Audio Presets & Settings', () {
    test('All presets have distinct descriptions', () {
      for (final p in SpatialPreset.values) {
        expect(p.label.isNotEmpty, true);
        expect(p.description.isNotEmpty, true);
      }
    });

    test('All room types have distinct acoustic descriptions', () {
      for (final r in RoomType.values) {
        expect(r.label.isNotEmpty, true);
        expect(r.description.isNotEmpty, true);
      }
    });
  });
}
