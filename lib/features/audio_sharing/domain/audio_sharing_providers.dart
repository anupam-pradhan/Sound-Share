import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'package:soundshare/features/audio_sharing/data/android_audio_sharing_service.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart'
    as model show BluetoothDeviceModel;

// ──────────────────────────────────────────────
// Audio Sharing Service Instance
// ──────────────────────────────────────────────

final audioSharingServiceProvider = Provider<AudioSharingService>((ref) {
  final service = AndroidAudioSharingService();
  ref.onDispose(service.dispose);
  return service;
});

// ──────────────────────────────────────────────
// Device Capability Provider
// ──────────────────────────────────────────────

final audioSharingCapabilityProvider =
    FutureProvider<AudioSharingCapability>((ref) async {
  final service = ref.watch(audioSharingServiceProvider);
  return service.canShareAudio();
});

// ──────────────────────────────────────────────
// Active Sharing Mode Provider
// ──────────────────────────────────────────────

final activeSharingModeProvider =
    StateNotifierProvider<ActiveSharingModeNotifier, AudioSharingMode>((ref) {
  return ActiveSharingModeNotifier(ref);
});

class ActiveSharingModeNotifier extends StateNotifier<AudioSharingMode> {
  ActiveSharingModeNotifier(this._ref)
      : super(AudioSharingMode.universalPeerShare) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<AudioSharingMode>? _sub;

  void _init() {
    final service = _ref.read(audioSharingServiceProvider);
    state = service.activeMode;
    _sub = service.activeModeStream.listen((mode) {
      state = mode;
    });

    // Auto-update to recommended mode once capability is resolved
    _ref.listen(audioSharingCapabilityProvider, (_, next) {
      if (next.hasValue) {
        setMode(next.value!.recommendedMode);
      }
    });
  }

  void setMode(AudioSharingMode mode) {
    state = mode;
    _ref.read(audioSharingServiceProvider).setActiveMode(mode);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Connected Peer Listeners Count Provider
// ──────────────────────────────────────────────

final connectedPeersCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(audioSharingServiceProvider);
  return service.connectedPeersCount;
});

// ──────────────────────────────────────────────
// Broadcast URL Provider
// ──────────────────────────────────────────────

final broadcastUrlProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(audioSharingServiceProvider);
  return service.broadcastUrlStream;
});

// ──────────────────────────────────────────────
// Audio Sharing State
// ──────────────────────────────────────────────

final audioSharingStateProvider =
    StateNotifierProvider<AudioSharingNotifier, AudioSharingState>((ref) {
  return AudioSharingNotifier(ref);
});

class AudioSharingNotifier extends StateNotifier<AudioSharingState> {
  AudioSharingNotifier(this._ref) : super(AudioSharingState.ready) {
    _ref.listen(connectedDevicesProvider,
        (_, devices) => _onConnectedDevicesChanged(devices));
    _ref.listen(activeSharingModeProvider,
        (_, mode) => _onModeChanged(mode));
  }

  final Ref _ref;
  StreamSubscription<bool>? _sharingSub;

  void _onConnectedDevicesChanged(List<model.BluetoothDeviceModel> devices) {
    if (state == AudioSharingState.sharing ||
        state == AudioSharingState.starting ||
        state == AudioSharingState.stopping) {
      return;
    }
    final mode = _ref.read(activeSharingModeProvider);
    if (mode == AudioSharingMode.universalPeerShare) {
      state = AudioSharingState.ready;
    } else {
      state = devices.isEmpty
          ? AudioSharingState.unavailable
          : AudioSharingState.ready;
    }
  }

  void _onModeChanged(AudioSharingMode mode) {
    if (state == AudioSharingState.sharing ||
        state == AudioSharingState.starting ||
        state == AudioSharingState.stopping) {
      return;
    }
    if (mode == AudioSharingMode.universalPeerShare) {
      state = AudioSharingState.ready;
    } else {
      final devices = _ref.read(connectedDevicesProvider);
      state = devices.isEmpty
          ? AudioSharingState.unavailable
          : AudioSharingState.ready;
    }
  }

  Future<void> startSharing() async {
    if (state != AudioSharingState.ready) return;
    state = AudioSharingState.starting;

    final service = _ref.read(audioSharingServiceProvider);
    try {
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
    if (state != AudioSharingState.sharing && state != AudioSharingState.starting) return;
    state = AudioSharingState.stopping;

    final service = _ref.read(audioSharingServiceProvider);
    try {
      await service.stopSharing();
    } catch (_) {
      // Ignore stop errors
    } finally {
      _sharingSub?.cancel();
      _sharingSub = null;
      state = AudioSharingState.ready;
    }
  }

  void resetError() {
    state = AudioSharingState.ready;
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
      } else {
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
