import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/spatial_audio_models.dart';
import '../domain/spatial_audio_service.dart';

/// Android native implementation of [SpatialAudioService].
class AndroidSpatialAudioService implements SpatialAudioService {
  static const _channel = MethodChannel('com.soundshare/spatial_audio');
  static const _eventsChannel = EventChannel('com.soundshare/spatial_audio_events');

  final _stateController = StreamController<SpatialAudioState>.broadcast();
  StreamSubscription? _eventSubscription;

  SpatialAudioPosition _currentPosition = const SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);
  bool _isActive = false;
  bool _isTesting = false;

  AndroidSpatialAudioService() {
    _initEventStream();
  }

  void _initEventStream() {
    try {
      _eventSubscription = _eventsChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final map = Map<String, dynamic>.from(event);
            final x = (map['x'] as num?)?.toDouble() ?? _currentPosition.x;
            final y = (map['y'] as num?)?.toDouble() ?? _currentPosition.y;
            final z = (map['z'] as num?)?.toDouble() ?? _currentPosition.z;
            final yaw = (map['yaw'] as num?)?.toDouble() ?? 0.0;
            final pitch = (map['pitch'] as num?)?.toDouble() ?? 0.0;
            final roll = (map['roll'] as num?)?.toDouble() ?? 0.0;
            _isTesting = map['isTesting'] as bool? ?? _isTesting;

            _currentPosition = SpatialAudioPosition(x: x, y: y, z: z);

            _stateController.add(
              SpatialAudioState(
                isActive: _isActive,
                position: _currentPosition,
                headYaw: yaw,
                headPitch: pitch,
                headRoll: roll,
                isTesting: _isTesting,
              ),
            );
          }
        },
        onError: (err) {
          // Fallback or stream error
        },
      );
    } catch (_) {}
  }

  @override
  Stream<SpatialAudioState> get state => _stateController.stream;

  @override
  Future<SpatialAudioCapabilities> getCapabilities() async {
    try {
      final res = await _channel.invokeMethod<Map>('getCapabilities');
      if (res != null) {
        return SpatialAudioCapabilities.fromMap(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return SpatialAudioCapabilities.empty();
  }

  @override
  Future<bool> enable() async {
    try {
      final success = await _channel.invokeMethod<bool>('enable') ?? true;
      _isActive = success;
      _emitState();
      return success;
    } catch (_) {
      _isActive = true;
      _emitState();
      return true;
    }
  }

  @override
  Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
    _isActive = false;
    _emitState();
  }

  @override
  Future<void> setPosition({
    required double x,
    required double y,
    required double z,
  }) async {
    _currentPosition = SpatialAudioPosition(x: x, y: y, z: z);
    _emitState();
    try {
      await _channel.invokeMethod('setPosition', {
        'x': x,
        'y': y,
        'z': z,
      });
    } catch (_) {}
  }

  @override
  Future<void> setDistance(double distance) async {
    try {
      await _channel.invokeMethod('setDistance', {'distance': distance});
    } catch (_) {}
  }

  @override
  Future<void> setImmersion(double value) async {
    try {
      await _channel.invokeMethod('setImmersion', {'immersion': value});
    } catch (_) {}
  }

  @override
  Future<void> setRoom(RoomType room) async {
    try {
      await _channel.invokeMethod('setRoom', {'room': room.name});
    } catch (_) {}
  }

  @override
  Future<void> setElevation(double elevation) async {
    try {
      await _channel.invokeMethod('setElevation', {'elevation': elevation});
    } catch (_) {}
  }

  @override
  Future<bool> enableHeadTracking() async {
    try {
      final success = await _channel.invokeMethod<bool>('enableHeadTracking') ?? false;
      return success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disableHeadTracking() async {
    try {
      await _channel.invokeMethod('disableHeadTracking');
    } catch (_) {}
  }

  @override
  Future<void> startTestAudio() async {
    _isTesting = true;
    _emitState();
    try {
      await _channel.invokeMethod('startTestAudio');
    } catch (_) {}
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(
        SpatialAudioState(
          isActive: _isActive,
          position: _currentPosition,
          headYaw: 0.0,
          headPitch: 0.0,
          headRoll: 0.0,
          isTesting: _isTesting,
        ),
      );
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _stateController.close();
  }
}
