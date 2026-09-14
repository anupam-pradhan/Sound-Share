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

/// The three audio sharing modes supported across 100% of Android devices.
enum AudioSharingMode {
  /// Direct 1-phone to 2-headphone Classic A2DP stream for Samsung One UI devices.
  samsungDualAudio,

  /// Next-Gen Bluetooth LE Audio / Auracast direct broadcast for Android 13+ & BT 5.2+.
  auracastBroadcast,

  /// Universal Peer-to-Peer Wi-Fi / Hotspot Audio Sync (Works on 100% of all smartphones).
  universalPeerShare,
}

extension AudioSharingModeExtension on AudioSharingMode {
  String get title {
    switch (this) {
      case AudioSharingMode.samsungDualAudio:
        return 'Samsung Dual Audio';
      case AudioSharingMode.auracastBroadcast:
        return 'Auracast Broadcast';
      case AudioSharingMode.universalPeerShare:
        return 'Universal Peer Share';
    }
  }

  String get subtitle {
    switch (this) {
      case AudioSharingMode.samsungDualAudio:
        return 'Direct dual Classic Bluetooth output (Samsung One UI)';
      case AudioSharingMode.auracastBroadcast:
        return 'Direct broadcast to LE Audio earbuds (Android 13+)';
      case AudioSharingMode.universalPeerShare:
        return 'Share in real time with a friend via Wi-Fi/Hotspot (100% of phones)';
    }
  }

  String get badgeText {
    switch (this) {
      case AudioSharingMode.samsungDualAudio:
        return 'SAMSUNG DIRECT';
      case AudioSharingMode.auracastBroadcast:
        return 'AURACAST LE';
      case AudioSharingMode.universalPeerShare:
        return '100% UNIVERSAL';
    }
  }
}

/// Capability info returned by the native layer.
class AudioSharingCapability {
  const AudioSharingCapability({
    required this.canShare,
    required this.reason,
    required this.androidVersion,
    this.deviceManufacturer = 'Unknown',
    this.deviceModel = 'Unknown',
    this.hasSamsungDualAudio = false,
    this.hasLeAudioBroadcast = false,
    this.recommendedMode = AudioSharingMode.universalPeerShare,
  });

  final bool canShare;
  final String reason;
  final int androidVersion;
  final String deviceManufacturer;
  final String deviceModel;
  final bool hasSamsungDualAudio;
  final bool hasLeAudioBroadcast;
  final AudioSharingMode recommendedMode;

  factory AudioSharingCapability.fromMap(Map<Object?, Object?> map) {
    final manufacturer = (map['deviceManufacturer'] as String?) ?? 'Unknown';
    final isSamsung = (map['hasSamsungDualAudio'] as bool?) ??
        manufacturer.toLowerCase().contains('samsung');
    final isLeAudio = (map['hasLeAudioBroadcast'] as bool?) ?? false;

    final recommendedStr = (map['recommendedMode'] as String?) ?? '';
    final recommendedMode = switch (recommendedStr) {
      'samsung_dual_audio' => AudioSharingMode.samsungDualAudio,
      'auracast_broadcast' => AudioSharingMode.auracastBroadcast,
      _ => isSamsung
          ? AudioSharingMode.samsungDualAudio
          : isLeAudio
              ? AudioSharingMode.auracastBroadcast
              : AudioSharingMode.universalPeerShare,
    };

    return AudioSharingCapability(
      canShare: (map['canShare'] as bool?) ?? true,
      reason: (map['reason'] as String?) ?? 'multi_mode_ready',
      androidVersion: (map['androidVersion'] as int?) ?? 30,
      deviceManufacturer: manufacturer,
      deviceModel: (map['deviceModel'] as String?) ?? 'Android Device',
      hasSamsungDualAudio: isSamsung,
      hasLeAudioBroadcast: isLeAudio,
      recommendedMode: recommendedMode,
    );
  }
}

/// Abstract interface for audio sharing service.
abstract class AudioSharingService {
  /// Whether the current device supports audio sharing and which modes are optimal.
  Future<AudioSharingCapability> canShareAudio();

  /// Start audio sharing.
  Future<void> startSharing();

  /// Stop audio sharing.
  Future<void> stopSharing();

  /// Currently active sharing mode.
  AudioSharingMode get activeMode;

  /// Stream of active sharing mode changes.
  Stream<AudioSharingMode> get activeModeStream;

  /// Set the active audio sharing mode.
  void setActiveMode(AudioSharingMode mode);

  /// Stream of sharing state updates.
  Stream<bool> get isSharing;

  /// Stream of audio latency in milliseconds.
  Stream<double> get latency;

  /// Local network broadcast URL when Universal Peer Sharing is active.
  String? get broadcastUrl;

  /// Stream of broadcast URL changes.
  Stream<String?> get broadcastUrlStream;

  /// Number of connected peer listeners.
  Stream<int> get connectedPeersCount;

  /// Open system Bluetooth settings.
  Future<bool> openBluetoothSettings();

  /// Open Android Media Output / Dual Audio switcher.
  Future<bool> openMediaOutputSelector();

  /// Dispose resources.
  void dispose();
}
