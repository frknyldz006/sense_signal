import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};

    if (Platform.isAndroid) {
      statuses = await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } else if (Platform.isIOS) {
      statuses = await [Permission.location, Permission.bluetooth].request();
    }

    bool allGranted = true;
    for (var status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }
    return allGranted;
  }
}
