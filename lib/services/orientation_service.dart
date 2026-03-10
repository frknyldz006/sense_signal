import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Provides current device orientation (azimuth)
final orientationProvider = StateNotifierProvider<OrientationNotifier, double>((
  ref,
) {
  return OrientationNotifier();
});

class OrientationNotifier extends StateNotifier<double> {
  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;

  List<double> _gravity = [0.0, 0.0, 0.0];
  List<double> _geomagnetic = [0.0, 0.0, 0.0];

  OrientationNotifier() : super(0.0) {
    _initSensors();
  }

  void _initSensors() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      // low pass filter to smooth gravity
      const alpha = 0.8;
      _gravity[0] = alpha * _gravity[0] + (1 - alpha) * event.x;
      _gravity[1] = alpha * _gravity[1] + (1 - alpha) * event.y;
      _gravity[2] = alpha * _gravity[2] + (1 - alpha) * event.z;
      _updateOrientation();
    });

    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      // low pass filter for magnetometer
      const alpha = 0.8;
      _geomagnetic[0] = alpha * _geomagnetic[0] + (1 - alpha) * event.x;
      _geomagnetic[1] = alpha * _geomagnetic[1] + (1 - alpha) * event.y;
      _geomagnetic[2] = alpha * _geomagnetic[2] + (1 - alpha) * event.z;
      _updateOrientation();
    });
  }

  void _updateOrientation() {
    // Cross product to get rotation matrix components
    double aX = _gravity[0], aY = _gravity[1], aZ = _gravity[2];
    double mX = _geomagnetic[0], mY = _geomagnetic[1], mZ = _geomagnetic[2];

    double hX = mY * aZ - mZ * aY;
    double hY = mZ * aX - mX * aZ;
    double hZ = mX * aY - mY * aX;

    double normH = sqrt(hX * hX + hY * hY + hZ * hZ);
    if (normH < 0.1) return; // Prevent division by zero or noisy flat readings

    hX /= normH;
    hY /= normH;
    hZ /= normH;

    double mY2 = aZ * hX - aX * hZ;

    // Azimuth is derived from M
    double azimuth = atan2(hY, mY2);

    // Filter to reduce jitter (simple lerp)
    double currentAzimuth = state;
    double diff = azimuth - currentAzimuth;

    // Normalize difference to [-pi, pi]
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;

    state = currentAzimuth + diff * 0.15; // Smooth transition
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}
