import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio_sharing/domain/audio_sharing_service.dart';
import '../../audio_sharing/data/android_audio_sharing_service.dart';
import '../bluetooth/domain/bluetooth_providers.dart';
import '../bluetooth/domain/bluetooth_device_model.dart';

// ──────────────────────────────────────────────
// Audio Sharing Service Instance
// ──────────────────────────────────────────────

final audioSharingServiceProvider = Provider<AudioSharingService>((ref) {
  final service = AndroidAudioSharingService();
  ref.onDispose(service.dispose);
  return service;
});

// ──────────────────────────────────────────────
// Audio Sharing State
// ──────────────────────────────────────────────

final audioSharingStateProvider =
    StateNotifierProvider<AudioSharingNotifier, AudioSharingState>((ref) {
  return AudioSharingNotifier(ref);
});

class AudioSharingNotifier extends StateNotifier<AudioSharingState> {
  AudioSharingNotifier(this._ref) : super(AudioSharingState.unavailable) {
    // Watch connected devices — update sharing availability
    _ref.listen(connectedDevicesProvider, (_, devices) {
      _onConnectedDevicesChanged(devices);
    });
  }

  final Ref _ref;
  StreamSubscription<bool>? _sharingSub;

  void _onConnectedDevicesChanged(List<BluetoothDeviceModel> devices) {
    if (state == AudioSharingState.sharing ||
        state == AudioSharingState.starting ||
        state == AudioSharingState.stopping) {
      // Don't interrupt active/transitioning state
      if (devices.isEmpty) {
        // Device disconnected while sharing — stop
        stopSharing();
      }
      return;
    }
    if (devices.isNotEmpty) {
      if (state == AudioSharingState.unavailable) {
        state = AudioSharingState.ready;
      }
    } else {
      state = AudioSharingState.unavailable;
    }
  }

  Future<void> startSharing() async {
    if (state != AudioSharingState.ready) return;
    state = AudioSharingState.starting;

    final service = _ref.read(audioSharingServiceProvider);

    try {
      final capability = await service.canShareAudio();
      if (!capability.canShare) {
        state = AudioSharingState.error;
        return;
      }
      await service.startSharing();
      _sharingSub?.cancel();
      _sharingSub = service.isSharing.listen((sharing) {
        if (!sharing && state == AudioSharingState.sharing) {
          state = AudioSharingState.ready;
        }
      });
      state = AudioSharingState.sharing;
    } catch (_) {
      state = AudioSharingState.error;
    }
  }

  Future<void> stopSharing() async {
    if (state != AudioSharingState.sharing) return;
    state = AudioSharingState.stopping;

    final service = _ref.read(audioSharingServiceProvider);
    try {
      await service.stopSharing();
    } catch (_) {
      // Ignore stop errors
    } finally {
      _sharingSub?.cancel();
      _sharingSub = null;
      final devices = _ref.read(connectedDevicesProvider);
      state = devices.isNotEmpty
          ? AudioSharingState.ready
          : AudioSharingState.unavailable;
    }
  }

  void resetError() {
    final devices = _ref.read(connectedDevicesProvider);
    state = devices.isNotEmpty
        ? AudioSharingState.ready
        : AudioSharingState.unavailable;
  }

  @override
  void dispose() {
    _sharingSub?.cancel();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Sharing duration timer
// ──────────────────────────────────────────────

final sharingDurationProvider =
    StateNotifierProvider<SharingDurationNotifier, Duration>((ref) {
  return SharingDurationNotifier(ref);
});

class SharingDurationNotifier extends StateNotifier<Duration> {
  SharingDurationNotifier(this._ref) : super(Duration.zero) {
    _ref.listen(audioSharingStateProvider, (_, next) {
      if (next == AudioSharingState.sharing) {
        _start();
      } else if (next != AudioSharingState.sharing) {
        _stop();
      }
    });
  }

  final Ref _ref;
  Timer? _timer;

  void _start() {
    state = Duration.zero;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state + const Duration(seconds: 1);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    state = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
