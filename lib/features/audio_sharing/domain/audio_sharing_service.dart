import 'dart:async';

/// Audio sharing state machine.
enum AudioSharingState {
  /// No secondary device connected — sharing unavailable.
  unavailable,

  /// Secondary device connected, ready to share.
  ready,

  /// Starting the audio sharing process.
  starting,

  /// Audio is actively being shared.
  sharing,

  /// Stopping the audio sharing process.
  stopping,

  /// An error occurred while trying to share.
  error,
}

/// Capability info returned by the native layer.
class AudioSharingCapability {
  const AudioSharingCapability({
    required this.canShare,
    required this.reason,
    required this.androidVersion,
  });

  final bool canShare;
  final String reason;
  final int androidVersion;

  factory AudioSharingCapability.fromMap(Map<Object?, Object?> map) {
    return AudioSharingCapability(
      canShare: (map['canShare'] as bool?) ?? false,
      reason: (map['reason'] as String?) ?? 'unknown',
      androidVersion: (map['androidVersion'] as int?) ?? 0,
    );
  }
}

/// Abstract interface for audio sharing service.
abstract class AudioSharingService {
  /// Whether the current device supports audio sharing.
  Future<AudioSharingCapability> canShareAudio();

  /// Start audio sharing to connected devices and local broadcast.
  Future<void> startSharing();

  /// Stop audio sharing.
  Future<void> stopSharing();

  /// Stream of sharing state updates.
  Stream<bool> get isSharing;

  /// Stream of audio latency in milliseconds (best-effort).
  Stream<double> get latency;

  /// Local network broadcast URL when sharing is active (for friend's phone).
  String? get broadcastUrl;

  /// Stream of broadcast URL changes.
  Stream<String?> get broadcastUrlStream;

  /// Open system Bluetooth settings.
  Future<bool> openBluetoothSettings();

  /// Open Android Media Output / Dual Audio switcher.
  Future<bool> openMediaOutputSelector();

  /// Dispose resources.
  void dispose();
}
