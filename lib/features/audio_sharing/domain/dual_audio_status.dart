/// How this phone can drive two headphones at once, as reported by the native layer.
enum DualAudioMode {
  /// Two distinct outputs exist (e.g. Bluetooth + wired/USB-C); SoundShare mirrors itself.
  appMirroring,

  /// Samsung One UI: user ticks both headphones in Media Output (system Dual Audio).
  samsungDualAudio,

  /// Android 15+/16 LE Audio earbuds: system "Audio sharing" plays to both.
  leAudioSharing,

  /// Two classic Bluetooth headphones connected, but Android only plays to one.
  singleActiveOnly,

  /// Fewer than two headphones connected.
  needSecondDevice,
}

class DualAudioBluetoothDevice {
  const DualAudioBluetoothDevice({
    required this.name,
    required this.address,
    required this.isActive,
  });

  final String name;
  final String address;

  /// Whether Android is currently sending media audio to this headphone.
  final bool isActive;

  factory DualAudioBluetoothDevice.fromMap(Map<Object?, Object?> map) {
    return DualAudioBluetoothDevice(
      name: (map['name'] as String?) ?? 'Bluetooth audio',
      address: (map['address'] as String?) ?? '',
      isActive: (map['isActive'] as bool?) ?? false,
    );
  }
}

class DualAudioStatus {
  const DualAudioStatus({
    required this.mode,
    required this.canAppPlayBoth,
    required this.connectedBluetoothCount,
    required this.hasWiredOrUsb,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    this.bluetoothDevices = const [],
  });

  static const unknown = DualAudioStatus(
    mode: DualAudioMode.needSecondDevice,
    canAppPlayBoth: false,
    connectedBluetoothCount: 0,
    hasWiredOrUsb: false,
    manufacturer: 'Android',
    model: '',
    androidVersion: 0,
  );

  final DualAudioMode mode;
  final bool canAppPlayBoth;
  final int connectedBluetoothCount;
  final bool hasWiredOrUsb;
  final String manufacturer;
  final String model;
  final int androidVersion;
  final List<DualAudioBluetoothDevice> bluetoothDevices;

  factory DualAudioStatus.fromMap(Map<Object?, Object?> map) {
    final mode = switch (map['mode'] as String?) {
      'app_mirroring' => DualAudioMode.appMirroring,
      'samsung_dual_audio' => DualAudioMode.samsungDualAudio,
      'le_audio_sharing' => DualAudioMode.leAudioSharing,
      'single_active_only' => DualAudioMode.singleActiveOnly,
      _ => DualAudioMode.needSecondDevice,
    };
    final rawDevices = (map['bluetoothDevices'] as List<Object?>?) ?? const [];
    return DualAudioStatus(
      mode: mode,
      canAppPlayBoth: (map['canAppPlayBoth'] as bool?) ?? false,
      connectedBluetoothCount: (map['connectedBluetoothCount'] as int?) ?? 0,
      hasWiredOrUsb: (map['hasWiredOrUsb'] as bool?) ?? false,
      manufacturer: (map['manufacturer'] as String?) ?? 'Android',
      model: (map['model'] as String?) ?? '',
      androidVersion: (map['androidVersion'] as int?) ?? 0,
      bluetoothDevices: List.unmodifiable(
        rawDevices
            .whereType<Map<Object?, Object?>>()
            .map(DualAudioBluetoothDevice.fromMap),
      ),
    );
  }
}
