import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/android_spatial_audio_service.dart';
import 'spatial_audio_models.dart';
import 'spatial_audio_service.dart';

/// Spatial audio service singleton provider
final spatialAudioServiceProvider = Provider<SpatialAudioService>((ref) {
  final service = AndroidSpatialAudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// Hardware & OS spatial audio capabilities provider
final spatialAudioCapabilitiesProvider =
    FutureProvider<SpatialAudioCapabilities>((ref) async {
  final service = ref.watch(spatialAudioServiceProvider);
  return await service.getCapabilities();
});

/// Real-time engine state stream
final spatialAudioStateProvider =
    StreamProvider.autoDispose<SpatialAudioState>((ref) {
  final service = ref.watch(spatialAudioServiceProvider);
  return service.state;
});

/// Spatial Audio Settings Notifier
final spatialAudioSettingsProvider =
    StateNotifierProvider<SpatialAudioSettingsNotifier, SpatialAudioSettings>((ref) {
  return SpatialAudioSettingsNotifier(ref);
});

class SpatialAudioSettingsNotifier extends StateNotifier<SpatialAudioSettings> {
  SpatialAudioSettingsNotifier(this._ref)
      : super(const SpatialAudioSettings()) {
    _loadSettings();
  }

  final Ref _ref;
  static const _kPrefEnabled = 'spatial_audio_enabled';
  static const _kPrefDistance = 'spatial_audio_distance';
  static const _kPrefImmersion = 'spatial_audio_immersion';
  static const _kPrefElevation = 'spatial_audio_elevation';
  static const _kPrefRoom = 'spatial_audio_room';
  static const _kPrefPreset = 'spatial_audio_preset';
  static const _kPrefHeadTracking = 'spatial_audio_head_tracking';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kPrefEnabled) ?? true;
      final distance = prefs.getDouble(_kPrefDistance) ?? 0.75;
      final immersion = prefs.getDouble(_kPrefImmersion) ?? 0.80;
      final elevation = prefs.getDouble(_kPrefElevation) ?? 0.0;
      final roomIdx = prefs.getInt(_kPrefRoom) ?? RoomType.cinema.index;
      final presetIdx = prefs.getInt(_kPrefPreset) ?? SpatialPreset.balanced.index;
      final headTracking = prefs.getBool(_kPrefHeadTracking) ?? false;

      state = state.copyWith(
        enabled: enabled,
        distance: distance,
        immersion: immersion,
        elevation: elevation,
        room: RoomType.values[roomIdx.clamp(0, RoomType.values.length - 1)],
        preset: SpatialPreset.values[presetIdx.clamp(0, SpatialPreset.values.length - 1)],
        headTracking: headTracking,
      );

      final service = _ref.read(spatialAudioServiceProvider);
      if (enabled) {
        await service.enable();
      } else {
        await service.disable();
      }
      await service.setDistance(distance);
      await service.setImmersion(immersion);
      await service.setElevation(elevation);
      await service.setRoom(state.room);
      if (headTracking) {
        await service.enableHeadTracking();
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool val) async {
    state = state.copyWith(enabled: val);
    final service = _ref.read(spatialAudioServiceProvider);
    if (val) {
      await service.enable();
    } else {
      await service.disable();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefEnabled, val);
  }

  Future<void> setPosition(SpatialAudioPosition pos) async {
    state = state.copyWith(position: pos);
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setPosition(x: pos.x, y: pos.y, z: pos.z);
  }

  Future<void> centerSound() async {
    const center = SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);
    await setPosition(center);
  }

  Future<void> setDistance(double distance) async {
    state = state.copyWith(distance: distance);
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setDistance(distance);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefDistance, distance);
  }

  Future<void> setImmersion(double immersion) async {
    state = state.copyWith(immersion: immersion);
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setImmersion(immersion);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefImmersion, immersion);
  }

  Future<void> setElevation(double elevation) async {
    state = state.copyWith(elevation: elevation);
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setElevation(elevation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefElevation, elevation);
  }

  Future<void> setRoom(RoomType room) async {
    state = state.copyWith(room: room);
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setRoom(room);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefRoom, room.index);
  }

  Future<void> setHeadTracking(bool val) async {
    state = state.copyWith(headTracking: val);
    final service = _ref.read(spatialAudioServiceProvider);
    if (val) {
      final success = await service.enableHeadTracking();
      if (!success) {
        state = state.copyWith(headTracking: false);
      }
    } else {
      await service.disableHeadTracking();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefHeadTracking, state.headTracking);
  }

  Future<void> applyPreset(SpatialPreset preset) async {
    SpatialAudioSettings updated;
    switch (preset) {
      case SpatialPreset.balanced:
        updated = state.copyWith(
          preset: preset,
          distance: 0.70,
          immersion: 0.75,
          room: RoomType.studio,
          position: const SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0),
        );
        break;
      case SpatialPreset.wide:
        updated = state.copyWith(
          preset: preset,
          distance: 0.85,
          immersion: 0.90,
          room: RoomType.live,
          position: const SpatialAudioPosition(x: 0.0, y: 0.9, z: 0.0),
        );
        break;
      case SpatialPreset.cinema:
        updated = state.copyWith(
          preset: preset,
          distance: 0.80,
          immersion: 0.95,
          room: RoomType.cinema,
          position: const SpatialAudioPosition(x: 0.0, y: 0.85, z: 0.1),
        );
        break;
      case SpatialPreset.gaming:
        updated = state.copyWith(
          preset: preset,
          distance: 0.60,
          immersion: 0.85,
          room: RoomType.studio,
          position: const SpatialAudioPosition(x: 0.0, y: 0.7, z: 0.0),
        );
        break;
      case SpatialPreset.immersive:
        updated = state.copyWith(
          preset: preset,
          distance: 0.90,
          immersion: 1.0,
          room: RoomType.openSpace,
          position: const SpatialAudioPosition(x: 0.0, y: 0.95, z: 0.2),
        );
        break;
    }

    state = updated;
    final service = _ref.read(spatialAudioServiceProvider);
    await service.setPosition(x: updated.position.x, y: updated.position.y, z: updated.position.z);
    await service.setDistance(updated.distance);
    await service.setImmersion(updated.immersion);
    await service.setElevation(updated.elevation);
    await service.setRoom(updated.room);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefPreset, preset.index);
  }

  Future<void> startTestAudio() async {
    final service = _ref.read(spatialAudioServiceProvider);
    await service.startTestAudio();
  }
}
