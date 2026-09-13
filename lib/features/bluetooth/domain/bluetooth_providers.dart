import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_device_model.dart' as model;

// ──────────────────────────────────────────────
// Bluetooth Adapter State
// ──────────────────────────────────────────────

final bluetoothAdapterStateProvider =
    StreamProvider<BluetoothAdapterState>((ref) {
  return FlutterBluePlus.adapterState;
});

// ──────────────────────────────────────────────
// Scanning State
// ──────────────────────────────────────────────

final isScanningProvider = StreamProvider<bool>((ref) {
  return FlutterBluePlus.isScanning;
});

// ──────────────────────────────────────────────
// Discovered Devices
// ──────────────────────────────────────────────

final discoveredDevicesProvider = StateNotifierProvider<
    DiscoveredDevicesNotifier, List<model.BluetoothDeviceModel>>((ref) {
  return DiscoveredDevicesNotifier(ref);
});

class DiscoveredDevicesNotifier
    extends StateNotifier<List<model.BluetoothDeviceModel>> {
  DiscoveredDevicesNotifier(this._ref) : super([]) {
    fetchBondedDevices();
  }

  final Ref _ref;
  StreamSubscription<List<ScanResult>>? _scanSub;
  static const _btChannel = MethodChannel('com.soundshare/bluetooth');

  /// Fetch paired/bonded audio devices from Android.
  Future<void> fetchBondedDevices() async {
    try {
      final List<dynamic>? bonded =
          await _btChannel.invokeMethod<List<dynamic>>('getBondedAudioDevices');
      if (bonded != null && bonded.isNotEmpty) {
        final currentConnected = _ref.read(connectedDevicesProvider);
        final list = <model.BluetoothDeviceModel>[];

        for (final item in bonded) {
          if (item is Map) {
            final addr = (item['address'] as String?) ?? '';
            final name = (item['name'] as String?) ?? '';
            final isConnected = (item['isConnected'] as bool?) ?? false;

            // Filter out unnamed or generic "Unknown Device"
            if (name.trim().isEmpty ||
                name.toLowerCase() == 'unknown device' ||
                name.toLowerCase().startsWith('unknown')) {
              continue;
            }

            final isAlreadyConnected = isConnected ||
                currentConnected.any((c) =>
                    (addr.isNotEmpty && c.id == addr) ||
                    c.name.toLowerCase() == name.toLowerCase());

            list.add(model.BluetoothDeviceModel(
              id: addr.isNotEmpty ? addr : name,
              name: name,
              type: _inferDeviceTypeFromName(name),
              connectionState: isAlreadyConnected
                  ? model.DeviceConnectionState.connected
                  : model.DeviceConnectionState.available,
            ));
          }
        }

        // Merge with current state
        final existingIds = state.map((d) => d.id).toSet();
        final newDevices = list.where((d) => !existingIds.contains(d.id)).toList();
        if (newDevices.isNotEmpty || state.isEmpty) {
          state = [...state, ...newDevices];
        }
      }
    } catch (_) {}
  }

  /// Start real Bluetooth scan + bonded audio devices.
  Future<void> startScan() async {
    state = []; // Clear previous results
    await fetchBondedDevices();

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final updated = List<model.BluetoothDeviceModel>.from(state);
      for (final result in results) {
        final advName = result.advertisementData.advName;
        final platformName = result.device.platformName;
        final devName = platformName.isNotEmpty
            ? platformName
            : (advName.isNotEmpty ? advName : '');

        // CRITICAL FIX: Skip any device that has no name or is "Unknown Device"
        if (devName.trim().isEmpty ||
            devName.toLowerCase() == 'unknown device' ||
            devName.toLowerCase().startsWith('unknown')) {
          continue;
        }

        final type = _resolveDeviceType(result);
        final devId = result.device.remoteId.str;

        final index = updated.indexWhere((d) => d.id == devId || d.name == devName);
        if (index >= 0) {
          updated[index] = updated[index].copyWith(
            rssi: result.rssi,
            name: devName,
          );
        } else {
          updated.add(model.BluetoothDeviceModel(
            id: devId,
            name: devName,
            type: type,
            connectionState: model.DeviceConnectionState.available,
            rssi: result.rssi,
          ));
        }
      }
      state = updated;
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: false,
      );
    } catch (_) {}
  }

  /// Stop current scan.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSub?.cancel();
    _scanSub = null;
  }

  /// Native A2DP connection to Bluetooth audio device
  Future<bool> connectAudioDevice(String address) async {
    try {
      final res = await _btChannel.invokeMethod<bool>(
        'connectAudioDevice',
        {'address': address},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Native A2DP disconnection from Bluetooth audio device
  Future<bool> disconnectAudioDevice(String address) async {
    try {
      final res = await _btChannel.invokeMethod<bool>(
        'disconnectAudioDevice',
        {'address': address},
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Update connection state for a specific device.
  void updateDeviceState(
      String id, model.DeviceConnectionState connectionState) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(connectionState: connectionState) else d,
    ];
  }

  model.BluetoothDeviceType _resolveDeviceType(ScanResult result) {
    return _inferFromAdvertisement(result);
  }

  model.BluetoothDeviceType _inferDeviceTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bud') || lower.contains('pod') || lower.contains('air')) {
      return model.BluetoothDeviceType.earbuds;
    }
    if (lower.contains('wh-') || lower.contains('head') || lower.contains('tune') || lower.contains('sony') || lower.contains('bose')) {
      return model.BluetoothDeviceType.headphones;
    }
    if (lower.contains('speaker') || lower.contains('sound') || lower.contains('flip') || lower.contains('boom') || lower.contains('jbl')) {
      return model.BluetoothDeviceType.speaker;
    }
    return model.BluetoothDeviceType.audioDevice;
  }

  model.BluetoothDeviceType _inferFromAdvertisement(ScanResult result) {
    final uuids = result.advertisementData.serviceUuids
        .map((u) => u.toString().toLowerCase())
        .toList();

    if (uuids.any((u) => u.contains('110b') || u.contains('110a'))) {
      return model.BluetoothDeviceType.headphones;
    }
    if (uuids.any((u) => u.contains('111e') || u.contains('1108'))) {
      return model.BluetoothDeviceType.earbuds;
    }
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;
    return _inferDeviceTypeFromName(name);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Connected Devices (Live Native Audio Sync)
// ──────────────────────────────────────────────

final connectedDevicesProvider = StateNotifierProvider<ConnectedDevicesNotifier,
    List<model.BluetoothDeviceModel>>((ref) {
  return ConnectedDevicesNotifier();
});

class ConnectedDevicesNotifier
    extends StateNotifier<List<model.BluetoothDeviceModel>> {
  ConnectedDevicesNotifier() : super([]) {
    _initNativeAudioListener();
    refreshConnectedDevices();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      refreshConnectedDevices();
    });
  }

  static const _audioChannel = MethodChannel('com.soundshare/audio');
  static const _audioEventsChannel = EventChannel('com.soundshare/audio_events');
  static const _btChannel = MethodChannel('com.soundshare/bluetooth');
  StreamSubscription<dynamic>? _audioEventSub;
  Timer? _pollTimer;

  void _initNativeAudioListener() {
    try {
      _audioEventSub = _audioEventsChannel.receiveBroadcastStream().listen((data) {
        refreshConnectedDevices();
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Query native Android for connected audio devices and update state.
  Future<void> refreshConnectedDevices() async {
    try {
      final List<dynamic>? devices =
          await _audioChannel.invokeMethod<List<dynamic>>('getAudioOutputDevices');

      if (devices != null) {
        final activeList = <model.BluetoothDeviceModel>[];

        for (final item in devices) {
          if (item is Map) {
            final isBt = (item['isBluetooth'] as bool?) ?? false;
            final typeStr = (item['type'] as String?) ?? '';
            final name = (item['productName'] as String?) ?? '';
            final id = (item['id'] as String?) ?? name;
            final address = (item['address'] as String?) ?? '';

            // Filter out empty / unknown names
            if (name.trim().isEmpty ||
                name.toLowerCase() == 'unknown device' ||
                name.toLowerCase().startsWith('unknown')) {
              continue;
            }

            // Only consider external audio sinks (Bluetooth headphones, headsets, wired, usb)
            if (isBt ||
                typeStr.contains('bluetooth') ||
                typeStr.contains('headphone') ||
                typeStr.contains('headset')) {
              model.BluetoothDeviceType dType = model.BluetoothDeviceType.headphones;
              final lower = name.toLowerCase();
              if (lower.contains('bud') || lower.contains('pod')) {
                dType = model.BluetoothDeviceType.earbuds;
              } else if (lower.contains('speaker')) {
                dType = model.BluetoothDeviceType.speaker;
              }

              // Retain volume/mute if already known
              final existing = state.firstWhere(
                (d) => d.id == id || (address.isNotEmpty && d.id == address) || d.name == name,
                orElse: () => model.BluetoothDeviceModel(
                  id: address.isNotEmpty ? address : id,
                  name: name,
                  type: dType,
                  connectionState: model.DeviceConnectionState.connected,
                ),
              );

              activeList.add(existing.copyWith(
                name: name,
                connectionState: model.DeviceConnectionState.connected,
              ));
            }
          }
        }

        // If we found active audio devices, update state
        if (activeList.isNotEmpty || state.isNotEmpty) {
          state = activeList;
        }
      }
    } catch (_) {}
  }

  void addDevice(model.BluetoothDeviceModel device) {
    if (device.name.trim().isEmpty ||
        device.name.toLowerCase() == 'unknown device' ||
        device.name.toLowerCase().startsWith('unknown')) {
      return;
    }

    if (!state.any((d) => d.id == device.id || d.name == device.name)) {
      state = [
        ...state,
        device.copyWith(
            connectionState: model.DeviceConnectionState.connected),
      ];
    }
  }

  void removeDevice(String id) {
    state = state.where((d) => d.id != id).toList();
  }

  void updateBattery(String id, int batteryLevel) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(batteryLevel: batteryLevel) else d,
    ];
  }

  void updateVolume(String id, double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(volumeLevel: clamped, isMuted: false) else d,
    ];
    try {
      _audioChannel.invokeMethod('setDeviceVolume', {
        'address': id,
        'volume': clamped,
      });
    } catch (_) {}
  }

  void toggleMute(String id) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(isMuted: !d.isMuted) else d,
    ];
    final updated = state.firstWhere((d) => d.id == id, orElse: () => state.first);
    try {
      _audioChannel.invokeMethod('setDeviceVolume', {
        'address': id,
        'volume': updated.isMuted ? 0.0 : updated.volumeLevel,
      });
    } catch (_) {}
  }

  /// Disconnect a connected audio device and remove from active list.
  /// Uses the class-level _btChannel instead of creating a new MethodChannel.
  Future<void> disconnectDevice(String id) async {
    removeDevice(id);
    try {
      await _btChannel.invokeMethod(
        'disconnectAudioDevice',
        {'address': id},
      );
    } catch (_) {}
    await refreshConnectedDevices();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _audioEventSub?.cancel();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Connecting in-progress set
// ──────────────────────────────────────────────

final connectingDeviceIdsProvider =
    StateProvider<Set<String>>((ref) => {});
