import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class SensorService {
  Stream<double> get headingStream {
    return magnetometerEventStream().map((MagnetometerEvent event) {
      double heading = atan2(event.y, event.x);
      return heading;
    });
  }
}
