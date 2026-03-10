import 'dart:math';

class SignalMath {
  /// Converts RSSI to absolute distance in meters.
  /// Distance Formula: d = 10 ^ ((TxPower - RSSI) / (10 * n))
  /// n = Path loss exponent (usually 2.0 for free space).
  /// TxPower is the reference RSSI at 1 meter.
  static double calculateDistance(
    int rssi, {
    int txPower = -59,
    double n = 2.0,
  }) {
    if (rssi == 0) return -1.0;
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }
}

/// A simple moving average filter to smooth out RSSI fluctuations.
class MovingAverageFilter {
  final int windowSize;
  final List<int> _values = [];

  MovingAverageFilter({this.windowSize = 5});

  void add(int value) {
    _values.add(value);
    if (_values.length > windowSize) {
      _values.removeAt(0);
    }
  }

  double get average {
    if (_values.isEmpty) return 0.0;
    return _values.fold(0, (sum, item) => sum + item) / _values.length;
  }

  void clear() {
    _values.clear();
  }
}
