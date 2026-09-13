import 'dart:math' as math;
import 'package:flutter/animation.dart';

/// Room environment types that alter reflection and reverb spatial processing.
enum RoomType {
  studio,
  cinema,
  live,
  openSpace;

  String get label {
    switch (this) {
      case RoomType.studio:
        return 'Studio';
      case RoomType.cinema:
        return 'Cinema';
      case RoomType.live:
        return 'Live';
      case RoomType.openSpace:
        return 'Open Space';
    }
  }

  String get description {
    switch (this) {
      case RoomType.studio:
        return 'Controlled reflections for crisp definition';
      case RoomType.cinema:
        return 'Wide cinematic acoustic field with deep staging';
      case RoomType.live:
        return 'Spacious stage acoustics with ambient resonance';
      case RoomType.openSpace:
        return 'Pure direct path with minimal room reverberation';
    }
  }
}

/// Spatial presets adjusting immersion, distance, and HRTF depth.
enum SpatialPreset {
  balanced,
  wide,
  cinema,
  gaming,
  immersive;

  String get label {
    switch (this) {
      case SpatialPreset.balanced:
        return 'Balanced';
      case SpatialPreset.wide:
        return 'Wide';
      case SpatialPreset.cinema:
        return 'Cinema';
      case SpatialPreset.gaming:
        return 'Gaming';
      case SpatialPreset.immersive:
        return 'Immersive';
    }
  }

  String get description {
    switch (this) {
      case SpatialPreset.balanced:
        return 'Natural stereo soundstage expansion';
      case SpatialPreset.wide:
        return 'Extended left/right separation for music';
      case SpatialPreset.cinema:
        return 'Frontal focus with ambient surround depth';
      case SpatialPreset.gaming:
        return 'Pinpoint 360° directional accuracy';
      case SpatialPreset.immersive:
        return 'Maximum binaural envelopment and room depth';
    }
  }
}

/// 3D Spatial Position in normalized Cartesian coordinates.
/// X = Left (-1.0) to Right (+1.0)
/// Y = Back (-1.0) to Front (+1.0)
/// Z = Below (-1.0) to Above (+1.0) (Elevation)
class SpatialAudioPosition {
  const SpatialAudioPosition({
    this.x = 0.0,
    this.y = 0.8,
    this.z = 0.0,
  });

  final double x;
  final double y;
  final double z;

  /// Angle in radians around listener (0 = Front, pi/2 = Right, pi = Back, -pi/2 = Left)
  double get azimuth => math.atan2(x, y);

  /// Angle in degrees around listener (0° = Front, 90° = Right, 180° = Back, 270° = Left)
  double get azimuthDegrees {
    double deg = azimuth * 180 / math.pi;
    if (deg < 0) deg += 360;
    return deg;
  }

  /// Distance from center listener (0.0 to 1.41)
  double get distance => math.sqrt(x * x + y * y);

  /// Accessible label for screen readers
  String toAccessibleLabel() {
    final distPercent = (distance * 100).toInt();
    String dir = 'Center';

    if (distance < 0.15) {
      dir = 'Center';
    } else if (y > 0.3 && x.abs() < 0.3) {
      dir = 'Front';
    } else if (y > 0.3 && x > 0.3) {
      dir = 'Front Right';
    } else if (y > 0.3 && x < -0.3) {
      dir = 'Front Left';
    } else if (y < -0.3 && x.abs() < 0.3) {
      dir = 'Back';
    } else if (y < -0.3 && x > 0.3) {
      dir = 'Back Right';
    } else if (y < -0.3 && x < -0.3) {
      dir = 'Back Left';
    } else if (x > 0.3) {
      dir = 'Right';
    } else if (x < -0.3) {
      dir = 'Left';
    }

    return 'Sound source position: $dir ($distPercent% distance)';
  }

  SpatialAudioPosition copyWith({
    double? x,
    double? y,
    double? z,
  }) {
    return SpatialAudioPosition(
      x: (x ?? this.x).clamp(-1.0, 1.0),
      y: (y ?? this.y).clamp(-1.0, 1.0),
      z: (z ?? this.z).clamp(-1.0, 1.0),
    );
  }

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'z': z,
      };

  factory SpatialAudioPosition.fromMap(Map<String, dynamic> map) {
    return SpatialAudioPosition(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.8,
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static SpatialAudioPosition lerp(
    SpatialAudioPosition? a,
    SpatialAudioPosition? b,
    double t,
  ) {
    if (a == null && b == null) return const SpatialAudioPosition();
    if (a == null) return b!;
    if (b == null) return a;
    return SpatialAudioPosition(
      x: a.x + (b.x - a.x) * t,
      y: a.y + (b.y - a.y) * t,
      z: a.z + (b.z - a.z) * t,
    );
  }
}

/// Tween for animating [SpatialAudioPosition] values.
class SpatialAudioPositionTween extends Tween<SpatialAudioPosition> {
  SpatialAudioPositionTween({super.begin, super.end});

  @override
  SpatialAudioPosition lerp(double t) =>
      SpatialAudioPosition.lerp(begin, end, t);
}

/// Hardware and OS spatial audio capabilities.
class SpatialAudioCapabilities {
  const SpatialAudioCapabilities({
    required this.supported,
    required this.supportsHeadTracking,
    required this.supportsSpatialization,
    required this.supportsBinaural,
    required this.supportsElevation,
    required this.rendererName,
  });

  final bool supported;
  final bool supportsHeadTracking;
  final bool supportsSpatialization;
  final bool supportsBinaural;
  final bool supportsElevation;
  final String rendererName;

  factory SpatialAudioCapabilities.empty() => const SpatialAudioCapabilities(
        supported: true,
        supportsHeadTracking: false,
        supportsSpatialization: true,
        supportsBinaural: true,
        supportsElevation: true,
        rendererName: 'SoundShare Binaural DSP Engine',
      );

  factory SpatialAudioCapabilities.fromMap(Map<String, dynamic> map) {
    return SpatialAudioCapabilities(
      supported: map['supported'] as bool? ?? true,
      supportsHeadTracking: map['supportsHeadTracking'] as bool? ?? false,
      supportsSpatialization: map['supportsSpatialization'] as bool? ?? true,
      supportsBinaural: map['supportsBinaural'] as bool? ?? true,
      supportsElevation: map['supportsElevation'] as bool? ?? true,
      rendererName:
          map['rendererName'] as String? ?? 'SoundShare Binaural DSP Engine',
    );
  }
}

/// Spatial Audio user settings.
class SpatialAudioSettings {
  const SpatialAudioSettings({
    this.enabled = true,
    this.position = const SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0),
    this.distance = 0.75,
    this.immersion = 0.80,
    this.elevation = 0.0,
    this.room = RoomType.cinema,
    this.headTracking = false,
    this.preset = SpatialPreset.balanced,
  });

  final bool enabled;
  final SpatialAudioPosition position;
  final double distance;
  final double immersion;
  final double elevation;
  final RoomType room;
  final bool headTracking;
  final SpatialPreset preset;

  SpatialAudioSettings copyWith({
    bool? enabled,
    SpatialAudioPosition? position,
    double? distance,
    double? immersion,
    double? elevation,
    RoomType? room,
    bool? headTracking,
    SpatialPreset? preset,
  }) {
    return SpatialAudioSettings(
      enabled: enabled ?? this.enabled,
      position: position ?? this.position,
      distance: (distance ?? this.distance).clamp(0.1, 1.0),
      immersion: (immersion ?? this.immersion).clamp(0.0, 1.0),
      elevation: (elevation ?? this.elevation).clamp(-1.0, 1.0),
      room: room ?? this.room,
      headTracking: headTracking ?? this.headTracking,
      preset: preset ?? this.preset,
    );
  }
}

/// Real-time state of the Spatial Audio rendering engine.
class SpatialAudioState {
  const SpatialAudioState({
    required this.isActive,
    required this.position,
    required this.headYaw,
    required this.headPitch,
    required this.headRoll,
    required this.isTesting,
  });

  final bool isActive;
  final SpatialAudioPosition position;
  final double headYaw;
  final double headPitch;
  final double headRoll;
  final bool isTesting;

  factory SpatialAudioState.initial() => const SpatialAudioState(
        isActive: false,
        position: SpatialAudioPosition(),
        headYaw: 0.0,
        headPitch: 0.0,
        headRoll: 0.0,
        isTesting: false,
      );
}
