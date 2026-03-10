class DeviceSignal {
  final String id; // MAC Address
  final String name; // Device Name (SSID or BLE Name)
  final String type; // 'BLE' or 'WiFi'
  final int rssi; // Current RSSI
  final double distance; // Estimated distance in meters
  final double angle; // Detected angle (azimuth in radians)
  final DateTime lastSeen; // Timestamp of the last update

  DeviceSignal({
    required this.id,
    required this.name,
    required this.type,
    required this.rssi,
    required this.distance,
    required this.angle,
    required this.lastSeen,
  });

  DeviceSignal copyWith({
    String? id,
    String? name,
    String? type,
    int? rssi,
    double? distance,
    double? angle,
    DateTime? lastSeen,
  }) {
    return DeviceSignal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      angle: angle ?? this.angle,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSignal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
