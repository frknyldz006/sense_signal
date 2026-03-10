import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class HardwareService {
  Future<bool> requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetooth,
    ].request();

    // Sıkıntılı cihazlarda bile scan deneyebilsin diye strict kontrolü kaldırdım
    return true; 
  }

  Stream<List<ScanResult>> get bleScanStream => FlutterBluePlus.scanResults;

  Future<void> startBleScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    try {
      await FlutterBluePlus.startScan(continuousUpdates: true);
    } catch(e) {
      // Ignore scan exceptions
    }
  }

  Future<void> stopBleScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<WiFiAccessPoint>> get wifiScanStream async* {
    while (true) {
      try {
        final canScan = await WiFiScan.instance.canStartScan();
        if (canScan == CanStartScan.yes) {
          await WiFiScan.instance.startScan();
          final results = await WiFiScan.instance.getScannedResults();
          yield results;
        }
      } catch(e) {
        // Ignore errors
      }
      await Future.delayed(const Duration(seconds: 4));
    }
  }
}
