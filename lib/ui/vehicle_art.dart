import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

class VehiclePhoto extends StatelessWidget {
  final double height;
  final bool detail;
  const VehiclePhoto({super.key, required this.height, this.detail = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF1F1EF),
                  Colors.white.withValues(alpha: .35),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: detail ? Alignment.center : Alignment.centerRight,
          child: Image.asset(
            'assets/honda_beat.png',
            height: detail ? height : height * 1.4,
            width: detail ? double.infinity : height * 1.4,
            fit: BoxFit.contain,
            alignment: detail ? Alignment.center : Alignment.centerRight,
            semanticLabel: 'Honda Beat merah dan hitam',
          ),
        ),
      ],
    ),
  );
}

class VehicleIllustration extends StatelessWidget {
  final double height;
  const VehicleIllustration({super.key, this.height = 120});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: VehiclePainter()),
  );
}

class VehiclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 130;
    final x = (size.width - 280 * scale) / 2;
    Offset pt(double dx, double dy) => Offset(x + dx * scale, dy * scale);
    final shadow = Paint()..color = const Color(0x1A171717);
    canvas.drawOval(
      Rect.fromCenter(
        center: pt(147, 116),
        width: 240 * scale,
        height: 12 * scale,
      ),
      shadow,
    );

    final wheel = Paint()..color = const Color(0xFF242528);
    final rim = Paint()..color = const Color(0xFFD5D5D0);
    final inner = Paint()..color = const Color(0xFF777A7A);
    for (final center in [pt(62, 99), pt(224, 99)]) {
      canvas.drawCircle(center, 25 * scale, wheel);
      canvas.drawCircle(center, 17 * scale, rim);
      canvas.drawCircle(center, 5 * scale, inner);
      final spokes = Paint()
        ..color = const Color(0xFF9B9D99)
        ..strokeWidth = 1.2 * scale;
      for (var i = 0; i < 8; i++) {
        final angle = i * 3.14159 / 4;
        canvas.drawLine(
          center +
              Offset(math.cos(angle) * 6 * scale, math.sin(angle) * 6 * scale),
          center +
              Offset(
                math.cos(angle) * 15 * scale,
                math.sin(angle) * 15 * scale,
              ),
          spokes,
        );
      }
    }

    final black = Paint()..color = const Color(0xFF28292C);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0403B), Color(0xFFC91D25), Color(0xFF8E171E)],
      ).createShader(Rect.fromLTWH(x, 15 * scale, 260 * scale, 95 * scale));
    final body = Path()
      ..moveTo(x + 37 * scale, 86 * scale)
      ..quadraticBezierTo(
        x + 40 * scale,
        68 * scale,
        x + 58 * scale,
        61 * scale,
      )
      ..lineTo(x + 91 * scale, 54 * scale)
      ..lineTo(x + 111 * scale, 30 * scale)
      ..quadraticBezierTo(
        x + 127 * scale,
        22 * scale,
        x + 152 * scale,
        26 * scale,
      )
      ..lineTo(x + 179 * scale, 43 * scale)
      ..lineTo(x + 201 * scale, 49 * scale)
      ..quadraticBezierTo(
        x + 222 * scale,
        55 * scale,
        x + 231 * scale,
        75 * scale,
      )
      ..lineTo(x + 228 * scale, 91 * scale)
      ..lineTo(x + 205 * scale, 91 * scale)
      ..quadraticBezierTo(
        x + 194 * scale,
        67 * scale,
        x + 175 * scale,
        68 * scale,
      )
      ..quadraticBezierTo(
        x + 153 * scale,
        68 * scale,
        x + 144 * scale,
        94 * scale,
      )
      ..lineTo(x + 96 * scale, 94 * scale)
      ..quadraticBezierTo(
        x + 87 * scale,
        73 * scale,
        x + 66 * scale,
        75 * scale,
      )
      ..quadraticBezierTo(
        x + 47 * scale,
        76 * scale,
        x + 43 * scale,
        94 * scale,
      )
      ..lineTo(x + 35 * scale, 93 * scale)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x55750E16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    final seat = Path()
      ..moveTo(x + 106 * scale, 32 * scale)
      ..quadraticBezierTo(
        x + 125 * scale,
        18 * scale,
        x + 153 * scale,
        25 * scale,
      )
      ..lineTo(x + 174 * scale, 39 * scale)
      ..lineTo(x + 148 * scale, 42 * scale)
      ..lineTo(x + 113 * scale, 41 * scale)
      ..close();
    canvas.drawPath(seat, black);
    canvas.drawPath(
      seat,
      Paint()
        ..color = const Color(0xFF48494B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scale,
    );

    final metal = Paint()
      ..color = const Color(0xFF525457)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pt(111, 58), pt(78, 88), metal);
    canvas.drawLine(pt(177, 63), pt(207, 85), metal);
    canvas.drawLine(pt(109, 89), pt(164, 89), metal);
    canvas.drawLine(pt(142, 89), pt(124, 62), metal);
    canvas.drawLine(pt(173, 63), pt(182, 91), metal);
    canvas.drawLine(
      pt(203, 51),
      pt(224, 49),
      Paint()
        ..color = const Color(0xFF252629)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(220, 48),
      pt(236, 65),
      Paint()
        ..color = const Color(0xFF252629)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );

    final glint = Paint()
      ..color = const Color(0xFFFFB7A9)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pt(155, 48), pt(179, 50), glint);
    canvas.drawLine(
      pt(220, 67),
      pt(230, 71),
      Paint()
        ..color = const Color(0xFFF8E9D9)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(44, 65),
      pt(32, 59),
      Paint()
        ..color = const Color(0xFF292A2C)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(34, 59),
      pt(29, 48),
      Paint()
        ..color = const Color(0xFF292A2C)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(39, 95),
      pt(54, 95),
      Paint()
        ..color = const Color(0xFF242528)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CarMark extends StatelessWidget {
  final double size;
  const CarMark({super.key, required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: CarMarkPainter()),
  );
}

class CarMarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(10, s.height * .62)
      ..quadraticBezierTo(
        s.width * .3,
        s.height * .2,
        s.width * .7,
        s.height * .4,
      )
      ..quadraticBezierTo(
        s.width * .9,
        s.height * .45,
        s.width - 8,
        s.height * .7,
      );
    c.drawPath(path, p);
    c.drawLine(
      Offset(12, s.height * .72),
      Offset(s.width - 12, s.height * .72),
      p,
    );
    c.drawCircle(Offset(s.width * .25, s.height * .75), 7, p);
    c.drawCircle(Offset(s.width * .75, s.height * .75), 7, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
