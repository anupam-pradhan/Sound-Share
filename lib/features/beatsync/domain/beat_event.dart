/// Beat classification derived from real audio analysis.
enum BeatType {
  kick,
  snare,
  transient,
  strongBeat,
  softBeat,
  drop,
}

/// Operational state of the BeatSync system.
enum BeatSyncStatus {
  off,
  ready,
  analyzing,
  active,
  unavailable,
}

/// Real-time beat event streamed from native audio analysis.
class BeatEvent {
  const BeatEvent({
    required this.timestamp,
    required this.strength,
    required this.type,
    this.energy = 0.0,
  });

  final DateTime timestamp;
  final double strength;
  final BeatType type;
  final double energy;

  factory BeatEvent.fromMap(Map<Object?, Object?> map) {
    final rawType = (map['type'] as String?)?.toLowerCase() ?? 'kick';
    final type = _parseBeatType(rawType);
    final strength = ((map['strength'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final energy = ((map['energy'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final rawTs = (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

    return BeatEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(rawTs),
      strength: strength,
      type: type,
      energy: energy,
    );
  }

  static BeatType _parseBeatType(String raw) {
    switch (raw) {
      case 'kick':
        return BeatType.kick;
      case 'snare':
        return BeatType.snare;
      case 'transient':
        return BeatType.transient;
      case 'strong_beat':
      case 'strongbeat':
        return BeatType.strongBeat;
      case 'soft_beat':
      case 'softbeat':
        return BeatType.softBeat;
      case 'drop':
        return BeatType.drop;
      default:
        return BeatType.kick;
    }
  }
}

/// Device haptic capabilities.
class HapticCapabilities {
  const HapticCapabilities({
    this.available = false,
    this.supportsAmplitude = false,
    this.supportsAdvancedEffects = false,
    this.androidVersion = 0,
  });

  final bool available;
  final bool supportsAmplitude;
  final bool supportsAdvancedEffects;
  final int androidVersion;

  factory HapticCapabilities.fromMap(Map<Object?, Object?> map) {
    return HapticCapabilities(
      available: (map['available'] as bool?) ?? false,
      supportsAmplitude: (map['supportsAmplitude'] as bool?) ?? false,
      supportsAdvancedEffects: (map['supportsAdvancedEffects'] as bool?) ?? false,
      androidVersion: (map['androidVersion'] as int?) ?? 0,
    );
  }
}

/// User configurable settings for the BeatSync haptic engine.
class BeatSyncSettings {
  const BeatSyncSettings({
    this.enabled = false,
    this.intensity = 1.0, // 0.5 (Low), 1.0 (Medium), 1.5 (High)
    this.sensitivity = 1.0, // 1.4 (Low), 1.0 (Medium), 0.7 (High)
    this.bassBoost = 1.3, // 1.0 (Off), 1.3 (Normal), 1.6 (Strong)
  });

  final bool enabled;
  final double intensity;
  final double sensitivity;
  final double bassBoost;

  BeatSyncSettings copyWith({
    bool? enabled,
    double? intensity,
    double? sensitivity,
    double? bassBoost,
  }) {
    return BeatSyncSettings(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
      sensitivity: sensitivity ?? this.sensitivity,
      bassBoost: bassBoost ?? this.bassBoost,
    );
  }
}
