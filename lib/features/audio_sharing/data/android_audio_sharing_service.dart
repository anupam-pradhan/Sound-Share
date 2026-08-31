import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/audio_sharing_service.dart';

/// Android implementation of [AudioSharingService] using MethodChannel
/// to query native AudioManager capabilities.
class AndroidAudioSharingService implements AudioSharingService {
  static const _channel = MethodChannel('com.soundshare/audio');

  final _sharingController = StreamController<bool>.broadcast();
  final _latencyController = StreamController<double>.broadcast();

  bool _isCurrentlySharing = false;

  @override
  Stream<bool> get isSharing => _sharingController.stream;

  @override
  Stream<double> get latency => _latencyController.stream;

  @override
  Future<AudioSharingCapability> canShareAudio() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('canShareAudio');
      if (result != null) {
        return AudioSharingCapability.fromMap(result);
      }
    } on PlatformException catch (_) {
      // Fall through to default
    }
    return const AudioSharingCapability(
      canShare: false,
      reason: 'platform_error',
      androidVersion: 0,
    );
  }

  @override
  Future<void> startSharing() async {
    if (_isCurrentlySharing) return;
    _isCurrentlySharing = true;
    _sharingController.add(true);

    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (_) {
      // Ignore if foreground service fails
    }

    _emitLatency(0);
  }

  @override
  Future<void> stopSharing() async {
    if (!_isCurrentlySharing) return;
    _isCurrentlySharing = false;
    _sharingController.add(false);
    _latencyController.add(0);

    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (_) {
      // Ignore stop errors
    }
  }

  void _emitLatency(double ms) {
    if (!_latencyController.isClosed) {
      _latencyController.add(ms);
    }
  }

  @override
  void dispose() {
    _sharingController.close();
    _latencyController.close();
  }
}
