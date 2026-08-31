import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bluetooth_device_model.dart';

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

final discoveredDevicesProvider =
    StateNotifierProvider<DiscoveredDevicesNotifier, List<BluetoothDeviceModel>>(
        (ref) {
  return DiscoveredDevicesNotifier(ref);
});

class DiscoveredDevicesNotifier
    extends StateNotifier<List<BluetoothDeviceModel>> {
  DiscoveredDevicesNotifier(this._ref) : super([]);

  final Ref _ref;
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// Start real Bluetooth scan.
  Future<void> startScan() async {
    state = []; // Clear previous results

    // Stop any active scan first
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final updated = <BluetoothDeviceModel>[];
      for (final result in results) {
        final type = _resolveDeviceType(result);
        // Only surface audio devices and unknowns
        final existing = state.firstWhere(
          (d) => d.id == result.device.remoteId.str,
          orElse: () => BluetoothDeviceModel(
            id: result.device.remoteId.str,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            type: type,
            connectionState: DeviceConnectionState.discovering,
            rssi: result.rssi,
          ),
        );

        // Transition discovering → available once we have a name
        final readyState = result.device.platformName.isNotEmpty
            ? DeviceConnectionState.available
            : DeviceConnectionState.discovering;

        updated.add(existing.copyWith(
          connectionState: existing.connectionState == DeviceConnectionState.connected
              ? DeviceConnectionState.connected
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
  void updateDeviceState(String id, DeviceConnectionState connectionState) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(connectionState: connectionState) else d,
    ];
  }

  BluetoothDeviceType _resolveDeviceType(ScanResult result) {
    // Use the device class from advertisement data
    final deviceClass = result.advertisementData.manufacturerData;
    // flutter_blue_plus exposes serviceUuids for BLE; for classic BT devices
    // we use the device type enum
    switch (result.device.type) {
      case BluetoothDeviceType.classic:
      case BluetoothDeviceType.dual:
        // For classic BT audio, try to infer from name patterns only as fallback
        // The primary source should be the Android BluetoothClass
        return _inferFromAdvertisement(result);
      case BluetoothDeviceType.le:
        return _inferFromAdvertisement(result);
      default:
        return BluetoothDeviceType.unknown;
    }
  }

  BluetoothDeviceType _inferFromAdvertisement(ScanResult result) {
    // Check advertised service UUIDs for standard audio profiles
    final uuids = result.advertisementData.serviceUuids
        .map((u) => u.toString().toLowerCase())
        .toList();

    // A2DP sink: 0000110b  A2DP source: 0000110a
    // Hands-free: 0000111e  Headset: 00001108
    // Hearing aid: 0000fdf0
    if (uuids.any((u) => u.contains('110b') || u.contains('110a'))) {
      // Has A2DP — check if headphones or speaker by other signals
      return BluetoothDeviceType.headphones;
    }
    if (uuids.any((u) => u.contains('111e') || u.contains('1108'))) {
      return BluetoothDeviceType.earbuds;
    }
    // Generic audio device
    if (result.advertisementData.serviceUuids.isNotEmpty) {
      return BluetoothDeviceType.audioDevice;
    }
    return BluetoothDeviceType.unknown;
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

final connectedDevicesProvider =
    StateNotifierProvider<ConnectedDevicesNotifier, List<BluetoothDeviceModel>>(
        (ref) {
  return ConnectedDevicesNotifier();
});

class ConnectedDevicesNotifier
    extends StateNotifier<List<BluetoothDeviceModel>> {
  ConnectedDevicesNotifier() : super([]);

  void addDevice(BluetoothDeviceModel device) {
    if (!state.any((d) => d.id == device.id)) {
      state = [
        ...state,
        device.copyWith(connectionState: DeviceConnectionState.connected),
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
// Connecting (in-progress)
// ──────────────────────────────────────────────

final connectingDeviceIdsProvider =
    StateProvider<Set<String>>((ref) => {});

// ──────────────────────────────────────────────
// Active connection subscriptions map
// ──────────────────────────────────────────────

final deviceConnectionSubsProvider =
    StateProvider<Map<String, StreamSubscription<BluetoothConnectionState>>>(
        (ref) => {});
