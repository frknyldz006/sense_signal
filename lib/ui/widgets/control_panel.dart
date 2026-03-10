import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/radar_provider.dart';
import 'glass_panel.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radarState = ref.watch(radarProvider);
    final notifier = ref.read(radarProvider.notifier);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATUS: ${radarState.isScanning ? "SCANNING" : "STANDBY"}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (radarState.isScanning) {
                    notifier.stopScanning();
                  } else {
                    notifier.startScanning();
                  }
                },
                child: Text(
                  radarState.isScanning ? 'HALT' : 'INITIALIZE',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEVICES DETECTED: ${radarState.devices.length}'),
              Text('HEADING: ${(radarState.currentHeading * 180 / 3.14159).toStringAsFixed(1)}°'),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: radarState.devices.length,
              itemBuilder: (context, index) {
                final d = radarState.devices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '[${d.type.name.toUpperCase()}] ${d.id.substring(max(0, d.id.length - 8))} : ${d.distance.toStringAsFixed(2)}m (RSSI: ${d.filteredRssi.toStringAsFixed(0)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: d.type.name == 'ble' 
                        ? const Color(0xFF39FF14) 
                        : const Color(0xFF00FFFF),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
