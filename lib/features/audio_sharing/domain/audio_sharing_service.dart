import 'dart:async';

import 'package:soundshare/features/audio_sharing/domain/dual_audio_status.dart';

export 'package:soundshare/features/audio_sharing/domain/dual_audio_status.dart';

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
        return 'Bluetooth';
      case AudioSharingMode.auracastBroadcast:
        return 'LE Audio';
      case AudioSharingMode.universalPeerShare:
        return 'Wi-Fi Share';
    }
  }

  String get subtitle {
    switch (this) {
      case AudioSharingMode.samsungDualAudio:
        return 'Two headphones via your phone\'s built-in dual audio';
      case AudioSharingMode.auracastBroadcast:
        return 'Android Audio Sharing for LE Audio earbuds';
      case AudioSharingMode.universalPeerShare:
        return 'Friends listen on their own phone over Wi-Fi or hotspot';
    }
  }

  String get badgeText {
    switch (this) {
      case AudioSharingMode.samsungDualAudio:
        return 'DUAL BLUETOOTH';
      case AudioSharingMode.auracastBroadcast:
        return 'AURACAST LE';
      case AudioSharingMode.universalPeerShare:
        return 'WI-FI SHARE';
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
    this.recommendedMode = AudioSharingMode.samsungDualAudio,
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
      'auracast_broadcast' => AudioSharingMode.auracastBroadcast,
      'universal_peer_share' => AudioSharingMode.universalPeerShare,
      _ => AudioSharingMode.samsungDualAudio,
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

  /// Open Android Developer Options (to configure Maximum Connected Bluetooth Audio Devices).
  Future<bool> openDeveloperSettings();

  /// Play a brief 0.35s pleasant test chime on all connected outputs to verify dual connection.
  Future<bool> playTestChime();

  /// What this phone can really do with two headphones right now.
  Future<DualAudioStatus> getDualAudioStatus();

  /// Open Android 15+/16 LE Audio "Audio sharing" (falls back to Bluetooth settings).
  Future<bool> openAudioSharingSettings();

  /// Dispose resources.
  void dispose();
}
