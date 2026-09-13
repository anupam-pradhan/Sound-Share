/// Bluetooth device category, derived from Android device class.
enum BluetoothDeviceType {
  earbuds,
  headphones,
  speaker,
  carAudio,
  audioDevice,
  phone,
  unknown,
}

/// Connection state of a discovered Bluetooth device.
enum DeviceConnectionState {
  available,
  discovering,
  connecting,
  connected,
  disconnecting,
  failed,
}

/// Immutable model representing a discovered Bluetooth audio device.
class BluetoothDeviceModel {
  const BluetoothDeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionState,
    this.batteryLevel,
    this.rssi,
    this.volumeLevel = 0.85,
    this.isMuted = false,
  });

  final String id;
  final String name;
  final BluetoothDeviceType type;
  final DeviceConnectionState connectionState;

  /// Null if the device has not reported battery info.
  final int? batteryLevel;

  /// Signal strength.
  final int? rssi;

  /// Individual volume level (0.0 to 1.0)
  final double volumeLevel;

  /// Whether this individual device is muted
  final bool isMuted;

  BluetoothDeviceModel copyWith({
    String? id,
    String? name,
    BluetoothDeviceType? type,
    DeviceConnectionState? connectionState,
    int? batteryLevel,
    int? rssi,
    double? volumeLevel,
    bool? isMuted,
  }) {
    return BluetoothDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionState: connectionState ?? this.connectionState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      rssi: rssi ?? this.rssi,
      volumeLevel: volumeLevel ?? this.volumeLevel,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Maps a Bluetooth major device class integer to [BluetoothDeviceType].
/// Uses the Android BluetoothClass.Device.Major constants.
BluetoothDeviceType deviceTypeFromClass(int? majorDeviceClass) {
  if (majorDeviceClass == null) return BluetoothDeviceType.unknown;
  // Android constants:
  // 0x0100 = AUDIO_VIDEO
  // 0x0200 = PHONE
  // 0x0400 = LAN_NETWORK_ACCESS_POINT
  // 0x0500 = IMAGING
  // 0x0600 = WEARABLE
  // 0x0700 = TOY
  // 0x0900 = HEALTH
  // 0x1F00 = UNCATEGORIZED
  switch (majorDeviceClass) {
    case 0x0100: // AUDIO_VIDEO — further refined by minor class
      return BluetoothDeviceType.audioDevice;
    case 0x0200: // PHONE
      return BluetoothDeviceType.phone;
    default:
      return BluetoothDeviceType.unknown;
  }
}

/// Refines audio device type using minor device class.
BluetoothDeviceType audioDeviceTypeFromMinorClass(int? minorDeviceClass) {
  if (minorDeviceClass == null) return BluetoothDeviceType.audioDevice;
  // Android minor classes for AUDIO_VIDEO (major 0x0100):
  // 0x0004 = HEADSET
  // 0x0008 = HANDSFREE
  // 0x0020 = MICROPHONE
  // 0x0028 = LOUDSPEAKER
  // 0x002C = HEADPHONES
  // 0x0030 = PORTABLE_AUDIO
  // 0x0034 = CAR_AUDIO
  // 0x0038 = SET_TOP_BOX
  // 0x003C = HIFI_AUDIO
  // 0x0040 = VCR
  // 0x0044 = VIDEO_CAMERA
  // 0x004C = CAMCORDER
  // 0x0050 = VIDEO_MONITOR
  // 0x0054 = VIDEO_DISPLAY_AND_LOUDSPEAKER
  // 0x0058 = VIDEO_CONFERENCING
  // 0x005C = GAMING_TOY
  switch (minorDeviceClass) {
    case 0x0004: // HEADSET
    case 0x0008: // HANDSFREE
      return BluetoothDeviceType.earbuds;
    case 0x002C: // HEADPHONES
      return BluetoothDeviceType.headphones;
    case 0x0028: // LOUDSPEAKER
    case 0x003C: // HIFI_AUDIO
      return BluetoothDeviceType.speaker;
    case 0x0034: // CAR_AUDIO
      return BluetoothDeviceType.carAudio;
    default:
      return BluetoothDeviceType.audioDevice;
  }
}
