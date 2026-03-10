import 'package:flutter/material.dart';
import '../../models/device_reading.dart';

class DeviceMarker extends StatelessWidget {
  final DeviceReading device;

  const DeviceMarker({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = device.type == DeviceType.ble 
      ? const Color(0xFF39FF14) 
      : const Color(0xFF00FFFF);

    // Get a short ID string like 'C8-92'
    String shortId = device.id.length > 5 
      ? device.id.substring(device.id.length - 5) 
      : device.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.5), width: 0.5),
          ),
          child: Text(
            shortId,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
