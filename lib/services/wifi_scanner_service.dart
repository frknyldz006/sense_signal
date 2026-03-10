import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_scan/wifi_scan.dart';

final wifiScannerProvider = Provider<WifiScannerService>((ref) {
  return WifiScannerService();
});

class WifiScannerService {
  StreamSubscription<List<WiFiAccessPoint>>? _scanSubscription;
  final StreamController<WiFiAccessPoint> _resultStreamController =
      StreamController<WiFiAccessPoint>.broadcast();
  Timer? _periodicScanTimer;

  Stream<WiFiAccessPoint> get results => _resultStreamController.stream;

  void startScan() async {
    // Check if WiFi is supported and enabled
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) return;

    // WiFi does not provide continuous streaming like BLE. We need to trigger it periodically.
    _periodicScanTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      await WiFiScan.instance.startScan();
    });

    _scanSubscription = WiFiScan.instance.onScannedResultsAvailable.listen((
      result,
    ) async {
      final results = await WiFiScan.instance.getScannedResults();
      for (var r in results) {
        _resultStreamController.add(r);
      }
    });
  }

  void stopScan() {
    _periodicScanTimer?.cancel();
    _scanSubscription?.cancel();
  }

  void dispose() {
    stopScan();
    _resultStreamController.close();
  }
}
