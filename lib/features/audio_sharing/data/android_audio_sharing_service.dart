import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:soundshare/core/ads/ad_service.dart';
import '../domain/audio_sharing_service.dart';
import 'peer_stream_server.dart';

/// Android implementation of [AudioSharingService].
///
/// * Bluetooth modes hand off to the phone's own dual-audio controls (Samsung
///   Dual Audio, LE Audio sharing) — the phone itself drives both headphones.
/// * Wi-Fi share captures what is playing on the phone and streams it to
///   friends' browsers through [PeerStreamServer].
class AndroidAudioSharingService implements AudioSharingService {
  static const _channel = MethodChannel('com.soundshare/audio');
  static const _pcmChannel = EventChannel('com.soundshare/pcm');

  final _sharingController = StreamController<bool>.broadcast();
  final _latencyController = StreamController<double>.broadcast();
  final _broadcastUrlController = StreamController<String?>.broadcast();
  final _activeModeController = StreamController<AudioSharingMode>.broadcast();
  final _server = PeerStreamServer();

  bool _isCurrentlySharing = false;
  String? _broadcastUrl;
  AudioSharingMode _activeMode = AudioSharingMode.universalPeerShare;
  StreamSubscription<dynamic>? _pcmSub;

  @override
  Stream<bool> get isSharing => _sharingController.stream;

  @override
  Stream<double> get latency => _latencyController.stream;

  @override
  String? get broadcastUrl => _broadcastUrl;

  @override
  Stream<String?> get broadcastUrlStream => _broadcastUrlController.stream;

  @override
  AudioSharingMode get activeMode => _activeMode;

  @override
  Stream<AudioSharingMode> get activeModeStream => _activeModeController.stream;

  @override
  Stream<int> get connectedPeersCount => _server.listenerCount;

  @override
  void setActiveMode(AudioSharingMode mode) {
    _activeMode = mode;
    _activeModeController.add(mode);
  }

  @override
  Future<AudioSharingCapability> canShareAudio() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('canShareAudio');
      if (result != null) {
        final capability = AudioSharingCapability.fromMap(result);
        setActiveMode(capability.recommendedMode);
        return capability;
      }
    } on PlatformException catch (_) {}

    const defaultCap = AudioSharingCapability(
      canShare: true,
      reason: 'multi_mode_ready',
      androidVersion: 30,
      recommendedMode: AudioSharingMode.universalPeerShare,
    );
    setActiveMode(defaultCap.recommendedMode);
    return defaultCap;
  }

  @override
  Future<void> startSharing() async {
    if (_isCurrentlySharing) return;
    if (_activeMode == AudioSharingMode.universalPeerShare) {
      await _startWifiShare();
    } else {
      // The phone's own dual-audio panel connects both headphones
      await openMediaOutputSelector();
    }
    _isCurrentlySharing = true;
    _sharingController.add(true);
  }

  Future<void> _startWifiShare() async {
    final url = await _server.start();
    if (url == null) {
      throw const AudioSharingException(
        'Connect to Wi-Fi or turn on your hotspot, then try again.',
      );
    }

    // Android shows its "start sharing your screen audio?" dialog here
    AdService.instance.suppressNextAppOpen();
    final Map<Object?, Object?>? reply;
    try {
      reply =
          await _channel.invokeMethod<Map<Object?, Object?>>('startCapture');
    } on PlatformException catch (e) {
      await _server.stop();
      throw AudioSharingException(e.message ?? 'Could not start sharing.');
    }
    if (reply?['ok'] != true) {
      await _server.stop();
      throw AudioSharingException(
        (reply?['reason'] as String?) ?? 'Could not start sharing.',
      );
    }

    _server.sampleRate = (reply?['sampleRate'] as int?) ?? 48000;
    _pcmSub = _pcmChannel.receiveBroadcastStream().listen(
      (chunk) {
        if (chunk is Uint8List) _server.broadcast(chunk);
      },
      // Stopped from Android's notification or capture failed: end the session
      onDone: _endFromSystem,
      onError: (Object _) => _endFromSystem(),
    );

    _broadcastUrl = url;
    _broadcastUrlController.add(url);
    _latencyController.add(250);
    try {
      await WakelockPlus.enable();
    } on PlatformException catch (_) {}
  }

  void _endFromSystem() {
    if (_isCurrentlySharing) stopSharing();
  }

  @override
  Future<void> stopSharing() async {
    if (!_isCurrentlySharing) return;
    _isCurrentlySharing = false;
    _sharingController.add(false);
    _latencyController.add(0);

    await _pcmSub?.cancel();
    _pcmSub = null;
    try {
      await _channel.invokeMethod('stopCapture');
    } on PlatformException catch (_) {}
    await _server.stop();
    _broadcastUrl = null;
    _broadcastUrlController.add(null);
    try {
      await WakelockPlus.disable();
    } on PlatformException catch (_) {}
  }

  @override
  Future<bool> openBluetoothSettings() async {
    AdService.instance.suppressNextAppOpen();
    try {
      final res = await _channel.invokeMethod<bool>('openBluetoothSettings');
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openMediaOutputSelector() async {
    AdService.instance.suppressNextAppOpen();
    try {
      final res = await _channel.invokeMethod<bool>('openMediaOutputSelector');
      return res ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pcmSub?.cancel();
    _server.dispose();
    _sharingController.close();
    _latencyController.close();
    _broadcastUrlController.close();
    _activeModeController.close();
  }
}
