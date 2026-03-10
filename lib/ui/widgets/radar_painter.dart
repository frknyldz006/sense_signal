import 'dart:math';
import 'package:flutter/material.dart';

class CartesianGridPainter extends CustomPainter {
  final double step;
  final Color gridColor;

  CartesianGridPainter({this.step = 30.0, this.gridColor = const Color(0xFF1B3320)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Uzun çizgiler
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Y eksenindeki rakamlar (sol taraf)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (double i = 0; i <= size.height; i += step) {
      if (i > 0 && i < size.height) {
        textPainter.text = TextSpan(
          text: (i / step).truncate().toString().padLeft(2, '0'),
          style: TextStyle(color: gridColor.withOpacity(0.8), fontSize: 10, fontFamily: 'monospace'),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(2, i - 6));
      }
    }

    // Mesafe Halkaları (Radar efekt)
    final center = Offset(size.width / 2, size.height / 2); // MY PHONE'un haritadaki yeri (Merkez)

    final ringPaint = Paint()
      ..color = const Color(0xFF39FF14).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1 Metre = 10 px, Örnek ölçek halkaları: 10m(100px), 25m(250px), 50m(500px)
    final List<double> distancesScale = [10.0, 25.0, 50.0];

    for (var d in distancesScale) {
       double radiusPx = d * 10; // `radar_provider` daki _scaleFactor varsayılan 10
       
       canvas.drawCircle(center, radiusPx, ringPaint);
       
       // Yalnızca okuma kılavuzu olacak Range (Mesafe) Metinleri
       textPainter.text = TextSpan(
         text: "${d.toInt()}M",
         style: TextStyle(color: const Color(0xFF39FF14).withOpacity(0.5), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
       );
       textPainter.layout();
       // Halkanın tepe merkezine + biraz sola as
       textPainter.paint(canvas, Offset(center.dx - 10, center.dy - radiusPx - 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadarCompassPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;

  RadarCompassPainter({required this.sweepAngle, this.color = const Color(0xFF39FF14)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final gridPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // İç içe çemberler
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), gridPaint);
    }

    // Çapraz çizgiler
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);

    // Dış kalın çerçeve
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Tarama animasyonu
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.4),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.95, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle,
      pi / 2,
      true,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadarCompassPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
