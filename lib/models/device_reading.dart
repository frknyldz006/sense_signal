import 'dart:collection';
import 'dart:math';

enum DeviceType { ble, wifi }

class DeviceReading {
  final String id;
  final String name;
  final double rssi;
  final DeviceType type;
  
  // Moving average filtered values
  final double filteredRssi;
  final double filteredAzimuth;
  
  final double distance;
  final double x;
  final double y;

  DeviceReading({
    required this.id,
    required this.name,
    required this.rssi,
    required this.type,
    required this.filteredRssi,
    required this.filteredAzimuth,
    required this.distance,
    required this.x,
    required this.y,
  });

  DeviceReading copyWith({
    String? name,
    double? rssi,
    double? filteredRssi,
    double? filteredAzimuth,
    double? distance,
    double? x,
    double? y,
  }) {
    return DeviceReading(
      id: id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      type: type,
      filteredRssi: filteredRssi ?? this.filteredRssi,
      filteredAzimuth: filteredAzimuth ?? this.filteredAzimuth,
      distance: distance ?? this.distance,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class MovingAverage {
  final int windowSize;
  final Queue<double> _values = Queue<double>();

  MovingAverage([this.windowSize = 5]);

  void add(double value) {
    _values.addLast(value);
    if (_values.length > windowSize) {
      _values.removeFirst();
    }
  }

  double get average {
    if (_values.isEmpty) return 0.0;
    return _values.reduce((a, b) => a + b) / _values.length;
  }
}
