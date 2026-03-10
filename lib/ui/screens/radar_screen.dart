import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/radar_provider.dart';
import '../../models/device_reading.dart';
import '../widgets/radar_painter.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  double _lastHeading = 0;
  double _cumulativeDegrees = 0;
  bool _isFirstHeading = true;

  double _getSmoothDegrees(double newHeadingRad) {
    double newDeg = newHeadingRad * 180 / pi;
    if (newDeg < 0) newDeg += 360;

    if (_isFirstHeading) {
      _cumulativeDegrees = newDeg;
      _lastHeading = newDeg;
      _isFirstHeading = false;
    } else {
      double diff = newDeg - _lastHeading;
      if (diff > 180) diff -= 360;
      else if (diff < -180) diff += 360;
      
      _cumulativeDegrees += diff;
      _lastHeading = newDeg;
    }
    return _cumulativeDegrees;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radarState = ref.watch(radarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), 
      body: SafeArea(
        child: Column(
          children: [
            // ÜST %60: Cartesian Grid & Top Map
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                   // BACKGROUND - GRID
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CartesianGridPainter(
                        step: 30.0,
                        gridColor: const Color(0xFF1B3320),
                      ),
                    ),
                  ),

                  // TOP TEXTS
                  Positioned(
                    top: 20, left: 20,
                    child: Text(
                      radarState.isScanning ? "SEARCHING" : "STANDBY", 
                      style: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        shadows: [BoxShadow(color: Color(0xFF39FF14), blurRadius: 10)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20, right: 20,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final locationAsync = ref.watch(locationProvider);
                        String latLngText = "LAT / LNG NA";
                        
                        locationAsync.whenData((pos) {
                          String formatCoord(double val) {
                            int d = val.abs().floor();
                            double remainder = (val.abs() - d) * 60;
                            int m = remainder.floor();
                            double s = (remainder - m) * 60;
                            return "$d°${m.toString().padLeft(2, '0')}'${s.toStringAsFixed(2).padLeft(5, '0')}\"";
                          }
                          
                          final latDir = pos.latitude >= 0 ? "N" : "S";
                          final lngDir = pos.longitude >= 0 ? "E" : "W";
                          latLngText = "${formatCoord(pos.latitude)} $latDir\n${formatCoord(pos.longitude)} $lngDir";
                        });

                        return Text(
                          "HEADING: ${(radarState.currentHeading * 180 / pi).toStringAsFixed(1)}°\n$latLngText",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            shadows: [BoxShadow(color: Color(0xFF39FF14), blurRadius: 5)],
                          ),
                        );
                      }
                    ),
                  ),

                  // KULLANICI (MY PHONE)
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.5), width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39FF14),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Color(0xFF39FF14), blurRadius: 10)],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "MY PHONE",
                            style: TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // CİHAZLAR
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Grid merkezi (MY PHONE yazısının orta konumu)
                      final centerPoint = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                      
                      return Stack(
                        children: radarState.devices.map((device) {
                          // 25 metreden uzak olan cihazları harita ekranında GÖSTERME
                          if (device.distance > 25.0) {
                            return const SizedBox.shrink();
                          }

                          // x2 çarpımını iptal edip mesafeyi standart tuttum
                          double deviceX = centerPoint.dx + device.x; 
                          double deviceY = centerPoint.dy + device.y;
          
                          // Eğer cihaz ekrandan çok uzaksa haritadan yok olması yerine ekranın kenarına yapışsın (opsiyonel clamp)
                          deviceX = deviceX.clamp(20.0, constraints.maxWidth - 40.0);
                          deviceY = deviceY.clamp(80.0, constraints.maxHeight - 40.0);

                          return Positioned(
                            left: deviceX,
                            top: deviceY,
                            child: _buildMarkerNode(
                              device.id.length > 5 ? device.id.substring(device.id.length - 5) : device.id, 
                              device.type,
                              device.distance,
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                ],
              ),
            ),
            
            // ALT %40: Glassmorphism Bottom Control
            Expanded(
              flex: 4,
              child: _buildBottomPanel(radarState, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerNode(String label, DeviceType type, double distanceRaw) {
    bool isBle = type == DeviceType.ble;
    Color nodeColor = isBle ? const Color(0xFF39FF14) : const Color(0xFF00FFFF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8, height: 8,
          color: nodeColor,
          child: Center(child: Icon(isBle ? Icons.bluetooth : Icons.wifi, size: 6, color: Colors.black)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: nodeColor, fontSize: 10, fontFamily: 'monospace')),
        Text("~${distanceRaw.toStringAsFixed(1)}m", style: TextStyle(color: nodeColor.withOpacity(0.7), fontSize: 8, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildBottomPanel(RadarState radarState, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2125).withOpacity(0.9), // Koyu arka plan
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Üst Kısım: Horizontal Compass Scale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double targetDegrees = _getSmoothDegrees(radarState.currentHeading);

                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: targetDegrees),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: CompassScalePainter(
                                headingDegrees: value,
                                activeColor: const Color(0xFF39FF14),
                              ),
                            );
                          }
                        );
                      }
                    ),
                  ),
                ),
              ),

              // Orta Kısım: Radar & Hoparlörler
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeakerGrill(),
                    
                    // Radar Pusula
                    GestureDetector(
                      onTap: () {
                         if (radarState.isScanning) {
                            ref.read(radarProvider.notifier).stopScanning();
                          } else {
                            ref.read(radarProvider.notifier).startScanning();
                          }
                      },
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, spreadRadius: 2),
                            BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.1), blurRadius: 20, spreadRadius: -5), // Yeşil parlama
                          ],
                        ),
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: RadarCompassPainter(
                                  sweepAngle: _animationController.value * 2 * pi,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    _buildSpeakerGrill(),
                  ],
                ),
              ),

              // En Alt: Butonlar (BLE & WIFI Tıklanabilir Cihaz Listesi)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBottomButton(Icons.track_changes, isActive: true, onTap: () {}),
                    _buildBottomButton(Icons.bluetooth, onTap: () => _showDeviceListModal(context, radarState, DeviceType.ble)),
                    _buildBottomButton(Icons.wifi, onTap: () => _showDeviceListModal(context, radarState, DeviceType.wifi)),
                    _buildBottomButton(Icons.settings, onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakerGrill() {
    return Row(
      children: List.generate(3, (c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: const [
                   BoxShadow(color: Colors.white10, offset: Offset(1,1), blurRadius: 1),
                ]
              ),
            ),
          )),
        ),
      )),
    );
  }

  Widget _buildBottomButton(IconData icon, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.black : const Color(0xFF2C2F33),
          boxShadow: isActive ? [
            BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
          ] : [
            const BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3)),
          ],
          border: isActive ? Border.all(color: const Color(0xFF39FF14).withOpacity(0.5), width: 1) : null,
        ),
        child: Icon(icon, color: isActive ? const Color(0xFF39FF14) : Colors.white70, size: 24),
      ),
    );
  }

  void _showDeviceListModal(BuildContext context, RadarState state, DeviceType type) {
    bool isBle = type == DeviceType.ble;
    String title = isBle ? "BLE DEVICES" : "WIFI TARGETS";
    Color themeColor = isBle ? const Color(0xFF39FF14) : const Color(0xFF00FFFF);

    final devices = state.devices.where((d) => d.type == type).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance)); // Yakından uzağa sırala

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: themeColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(isBle ? Icons.bluetooth : Icons.wifi, color: themeColor),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(color: themeColor, fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${devices.length} FOUND', style: TextStyle(color: themeColor, fontFamily: 'monospace')),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: devices.isEmpty 
                  ? Center(
                      child: Text(
                        "NO ${isBle ? 'BLE' : 'WIFI'} DEVICES DETECTED",
                        style: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                      ),
                    )
                  : ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (ctx, i) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (ctx, i) {
                    final d = devices[i];
                    final String guessedType = _guessDeviceType(d.name, d.id, d.type);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: themeColor.withOpacity(0.1),
                        child: Icon(
                          _getIconForType(guessedType, isBle),
                          color: themeColor, size: 20
                        ),
                      ),
                      title: Text(d.name.isNotEmpty && d.name != 'Unknown BLE' && d.name != 'Unknown WiFi' ? d.name : "ID: ${d.id}", 
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('TYPE: $guessedType', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                          Text('RSSI: ${d.filteredRssi.toStringAsFixed(0)} dBm', style: TextStyle(color: themeColor.withOpacity(0.8), fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('~${d.distance.toStringAsFixed(1)}m', style: TextStyle(color: themeColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          const Text('DISTANCE', style: TextStyle(color: Colors.white54, fontSize: 8, fontFamily: 'monospace')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  IconData _getIconForType(String typeStr, bool isBle) {
    if (typeStr.contains('TV')) return Icons.tv;
    if (typeStr.contains('Bilgisayar')) return Icons.computer;
    if (typeStr.contains('Akıllı Saat')) return Icons.watch;
    if (typeStr.contains('Kulaklık')) return Icons.headphones;
    if (typeStr.contains('Kamera')) return Icons.camera_alt;
    if (typeStr.contains('Akıllı Telefon')) return Icons.smartphone;
    if (typeStr.contains('Router')) return Icons.router;
    if (typeStr.contains('Yazıcı')) return Icons.print;
    if (typeStr.contains('Aydınlatma')) return Icons.lightbulb;
    return isBle ? Icons.bluetooth_audio : Icons.device_hub;
  }

  String _guessDeviceType(String name, String id, DeviceType type) {
    String lowerName = name.toLowerCase();
    
    if (lowerName.contains('tv') || lowerName.contains('samsung') || lowerName.contains('lg')) return 'Akıllı TV / Monitör';
    if (lowerName.contains('mac') || lowerName.contains('pc') || lowerName.contains('desktop') || lowerName.contains('laptop') || lowerName.contains('book')) return 'Bilgisayar';
    if (lowerName.contains('watch') || lowerName.contains('band') || lowerName.contains('garmin') || lowerName.contains('fitbit') || lowerName.contains('mi band')) return 'Akıllı Saat / Giyilebilir';
    if (lowerName.contains('airpods') || lowerName.contains('buds') || lowerName.contains('headset') || lowerName.contains('audio') || lowerName.contains('jbl') || lowerName.contains('bose')) return 'Kulaklık / Ses Cihazı';
    if (lowerName.contains('cam') || lowerName.contains('gopro') || lowerName.contains('yi')) return 'Kamera (Olası Gizli Kamera)';
    if (lowerName.contains('iphone') || lowerName.contains('phone') || lowerName.contains('galaxy') || lowerName.contains('pixel')) return 'Akıllı Telefon';
    if (lowerName.contains('router') || lowerName.contains('wifi') || lowerName.contains('mesh') || lowerName.contains('netgear') || lowerName.contains('tplink') || lowerName.contains('superonline') || lowerName.contains('turktelekom')) return 'Router / Modem / Ağ Kapısı';
    if (lowerName.contains('printer') || lowerName.contains('hp') || lowerName.contains('canon') || lowerName.contains('epson')) return 'Yazıcı / Tarayıcı';
    if (lowerName.contains('hue') || lowerName.contains('bulb') || lowerName.contains('light')) return 'Akıllı Aydınlatma';
    
    if (type == DeviceType.ble) {
      return 'Bilinmeyen BLE Cihazı (Aksesuar, Hoparlör vb.)';
    } else {
      return 'Bilinmeyen Wi-Fi Cihazı (Ağ, IoT vb.)';
    }
  }
}

class CompassScalePainter extends CustomPainter {
  final double headingDegrees;
  final Color activeColor;

  CompassScalePainter({required this.headingDegrees, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final pxPerDegree = 4.0; // 1 derece 4 piksel boşluk kaplar
    
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2;

    final textStyle = const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace');
    final activeTextStyle = TextStyle(color: activeColor, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold);

    // Dizeceğimiz aralık (ekran genişliğine göre görülecek alan)
    int minDegree = (headingDegrees - (center / pxPerDegree)).floor();
    int maxDegree = (headingDegrees + (center / pxPerDegree)).ceil();

    for (int i = minDegree; i <= maxDegree; i++) {
       if (i % 5 == 0) { // Her 5 derecede bir çizgi
         double dx = center + (i - headingDegrees) * pxPerDegree;
         bool isCenter = (i - headingDegrees).abs() < 5; // Merkezdekine yakın mı
         
         if (i % 10 == 0) { // 10'un katlarında sayı ve uzun çizgi
           canvas.drawLine(Offset(dx, size.height - 15), Offset(dx, size.height), isCenter ? activePaint : paint);
           
           int displayDegree = i % 360;
           if (displayDegree < 0) displayDegree += 360; // Negatifleri döndür

           String label = displayDegree.toString();
           if (displayDegree == 0) label = 'N';
           else if (displayDegree == 90) label = 'E';
           else if (displayDegree == 180) label = 'S';
           else if (displayDegree == 270) label = 'W';

           final textPainter = TextPainter(
             text: TextSpan(text: label, style: isCenter ? activeTextStyle : textStyle),
             textDirection: TextDirection.ltr,
           );
           textPainter.layout();
           textPainter.paint(canvas, Offset(dx - textPainter.width / 2, size.height - 30));
         } else { // 5'in katlarında kısa çizgi
           canvas.drawLine(Offset(dx, size.height - 8), Offset(dx, size.height), paint);
         }
       }
    }
    
    // Merkez hedef çizgi imleci
    canvas.drawLine(Offset(center, 0), Offset(center, size.height), activePaint);
  }

  @override
  bool shouldRepaint(covariant CompassScalePainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees;
  }
}
