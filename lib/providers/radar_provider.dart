import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../models/device_reading.dart';
import '../services/hardware_service.dart';
import '../services/sensor_service.dart';

final hardwareServiceProvider = Provider((ref) => HardwareService());
final sensorServiceProvider = Provider((ref) => SensorService());

final compassProvider = StreamProvider<double>((ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.headingStream;
});

final locationProvider = StreamProvider<Position>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    ),
  );
});

class RadarState {
  final List<DeviceReading> devices;
  final bool isScanning;
  final double currentHeading;

  RadarState({
    this.devices = const [],
    this.isScanning = false,
    this.currentHeading = 0.0,
  });

  RadarState copyWith({
    List<DeviceReading>? devices,
    bool? isScanning,
    double? currentHeading,
  }) {
    return RadarState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      currentHeading: currentHeading ?? this.currentHeading,
    );
  }
}

class RadarNotifier extends StateNotifier<RadarState> {
  final HardwareService _hardwareService;
  StreamSubscription? _bleSub;
  StreamSubscription? _wifiSub;

  final Map<String, MovingAverage> _rssiFilters = {};
  final Map<String, DeviceReading> _devicesMap = {};

  final double _scaleFactor = 10.0; // 1 meter = 10 pixels

  RadarNotifier(this._hardwareService) : super(RadarState());

  void updateHeading(double heading) {
    state = state.copyWith(currentHeading: heading);
    _recalculatePositions();
  }

  Future<void> startScanning() async {
    final hasPerms = await _hardwareService.requestPermissions();
    if (!hasPerms) return;

    await _hardwareService.startBleScan();
    state = state.copyWith(isScanning: true);

    _bleSub?.cancel();
    _bleSub = _hardwareService.bleScanStream.listen((results) {
      for (var r in results) {
        _processDevice(
          id: r.device.remoteId.str,
          name: r.device.platformName.isEmpty
              ? 'Unknown BLE'
              : r.device.platformName,
          rssi: r.rssi.toDouble(),
          type: DeviceType.ble,
          txPower: -59,
          pathLossExponent: 3.0, // İç mekan için 2.0 (açık alan) yerine 3.0 daha gerçekçidir
        );
      }
    });

    _wifiSub?.cancel();
    _wifiSub = _hardwareService.wifiScanStream.listen((results) {
      for (var r in results) {
        _processDevice(
          id: r.bssid,
          name: r.ssid.isEmpty ? 'Unknown WiFi' : r.ssid,
          rssi: r.level.toDouble(),
          type: DeviceType.wifi,
          txPower: -50,
          pathLossExponent: 3.5, // Duvarlar/Odalar için Wi-Fi sinyal kaybı
        );
      }
    });
  }

  void stopScanning() {
    _hardwareService.stopBleScan();
    _bleSub?.cancel();
    _wifiSub?.cancel();
    state = state.copyWith(isScanning: false);
  }

  void _processDevice({
    required String id,
    required String name,
    required double rssi,
    required DeviceType type,
    required double txPower,
    required double pathLossExponent,
  }) {
    _rssiFilters.putIfAbsent(id, () => MovingAverage(5));
    _rssiFilters[id]!.add(rssi);
    double filteredRssi = _rssiFilters[id]!.average;

    double distance = pow(
      10,
      (txPower - filteredRssi) / (10 * pathLossExponent),
    ).toDouble();

    int idHash = id.hashCode;
    double baseAngle = (idHash % 360) * pi / 180.0;
    double angle = baseAngle - state.currentHeading;

    double x = distance * _scaleFactor * cos(angle);
    double y = distance * _scaleFactor * sin(angle);

    _devicesMap[id] = DeviceReading(
      id: id,
      name: name,
      rssi: rssi,
      type: type,
      filteredRssi: filteredRssi,
      filteredAzimuth: angle,
      distance: distance,
      x: x,
      y: y,
    );

    state = state.copyWith(devices: _devicesMap.values.toList());
  }

  void _recalculatePositions() {
    for (var key in _devicesMap.keys) {
      var d = _devicesMap[key]!;
      int idHash = d.id.hashCode;
      double baseAngle = (idHash % 360) * pi / 180.0;
      double angle = baseAngle - state.currentHeading;

      double x = d.distance * _scaleFactor * cos(angle);
      double y = d.distance * _scaleFactor * sin(angle);

      _devicesMap[key] = d.copyWith(filteredAzimuth: angle, x: x, y: y);
    }
    state = state.copyWith(devices: _devicesMap.values.toList());
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _wifiSub?.cancel();
    super.dispose();
  }
}

final radarProvider = StateNotifierProvider<RadarNotifier, RadarState>((ref) {
  final hw = ref.watch(hardwareServiceProvider);
  final notifier = RadarNotifier(hw);

  ref.listen<AsyncValue<double>>(compassProvider, (previous, next) {
    if (next.hasValue) {
      notifier.updateHeading(next.value!);
    }
  });

  return notifier;
});
