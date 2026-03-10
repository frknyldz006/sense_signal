import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bleScannerProvider = Provider<BleScannerService>((ref) {
  return BleScannerService();
});

class BleScannerService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<ScanResult> _resultStreamController =
      StreamController<ScanResult>.broadcast();

  Stream<ScanResult> get results => _resultStreamController.stream;

  void startScan() async {
    // Check if adapter is on
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (ScanResult r in results) {
          _resultStreamController.add(r);
        }
      });
      // Start scanning continuously
      FlutterBluePlus.startScan(continuousUpdates: true);
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  void dispose() {
    stopScan();
    _resultStreamController.close();
  }
}
