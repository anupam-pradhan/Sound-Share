import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_device_model.dart'
    as model
    show BluetoothDeviceModel, BluetoothDeviceType, DeviceConnectionState;

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
  DiscoveredDevicesNotifier(Ref ref) : super([]);

  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Start real Bluetooth scan.
  Future<void> startScan() async {
    state = []; // Clear previous results

    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final updated = <model.BluetoothDeviceModel>[];
      for (final result in results) {
        final type = _resolveDeviceType(result);
        final existing = state.firstWhere(
          (d) => d.id == result.device.remoteId.str,
          orElse: () => model.BluetoothDeviceModel(
            id: result.device.remoteId.str,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            type: type,
            connectionState: model.DeviceConnectionState.discovering,
            rssi: result.rssi,
          ),
        );

        final readyState = result.device.platformName.isNotEmpty
            ? model.DeviceConnectionState.available
            : model.DeviceConnectionState.discovering;

        updated.add(existing.copyWith(
          connectionState:
              existing.connectionState == model.DeviceConnectionState.connected
                  ? model.DeviceConnectionState.connected
                  : readyState,
          rssi: result.rssi,
        ));
      }
      state = updated;
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );
  }

  /// Stop current scan.
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
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

  model.BluetoothDeviceType _inferFromAdvertisement(ScanResult result) {
    final uuids = result.advertisementData.serviceUuids
        .map((u) => u.toString().toLowerCase())
        .toList();

    // A2DP: 0000110b / 0000110a
    if (uuids.any((u) => u.contains('110b') || u.contains('110a'))) {
      return model.BluetoothDeviceType.headphones;
    }
    // Hands-free: 0000111e / Headset: 00001108
    if (uuids.any((u) => u.contains('111e') || u.contains('1108'))) {
      return model.BluetoothDeviceType.earbuds;
    }
    if (result.advertisementData.serviceUuids.isNotEmpty) {
      return model.BluetoothDeviceType.audioDevice;
    }
    return model.BluetoothDeviceType.unknown;
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Connected Devices
// ──────────────────────────────────────────────

final connectedDevicesProvider = StateNotifierProvider<ConnectedDevicesNotifier,
    List<model.BluetoothDeviceModel>>((ref) {
  return ConnectedDevicesNotifier();
});

class ConnectedDevicesNotifier
    extends StateNotifier<List<model.BluetoothDeviceModel>> {
  ConnectedDevicesNotifier() : super([]);

  void addDevice(model.BluetoothDeviceModel device) {
    if (!state.any((d) => d.id == device.id)) {
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
}

// ──────────────────────────────────────────────
// Connecting in-progress set
// ──────────────────────────────────────────────

final connectingDeviceIdsProvider =
    StateProvider<Set<String>>((ref) => {});
