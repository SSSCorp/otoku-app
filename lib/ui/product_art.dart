import 'package:flutter/material.dart';

class ProductArt extends StatelessWidget {
  final String icon;
  final String? image;
  const ProductArt({super.key, required this.icon, this.image});
  @override
  Widget build(BuildContext c) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F1ED),
      borderRadius: BorderRadius.circular(14),
    ),
    child: image == null || image!.isEmpty
        ? CustomPaint(painter: PartPainter(icon))
        : Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              image!,
              fit: BoxFit.contain,
              semanticLabel: 'Foto produk ilustrasi',
              errorBuilder: (_, _, _) =>
                  CustomPaint(painter: PartPainter(icon)),
            ),
          ),
  );
}

class PartPainter extends CustomPainter {
  final String type;
  PartPainter(this.type);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 68;
    final center = Offset(size.width / 2, size.height / 2);
    final shadow = Paint()..color = const Color(0x20000000);
    final dark = Paint()..color = const Color(0xFF35373A);
    if (type == 'brake') {
      final pad = Path()
        ..moveTo(16 * scale, 20 * scale)
        ..quadraticBezierTo(20 * scale, 15 * scale, 29 * scale, 16 * scale)
        ..lineTo(52 * scale, 23 * scale)
        ..lineTo(48 * scale, 47 * scale)
        ..quadraticBezierTo(35 * scale, 53 * scale, 19 * scale, 46 * scale)
        ..close();
      canvas.drawPath(pad.shift(Offset(0, 3 * scale)), shadow);
      canvas.drawPath(
        pad,
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFF5C6062), Color(0xFF292B2D)],
              ).createShader(
                Rect.fromLTWH(12 * scale, 14 * scale, 44 * scale, 40 * scale),
              ),
      );
      canvas.drawPath(
        pad,
        Paint()
          ..color = const Color(0xFF8C8E8C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * scale,
      );
      final groove = Paint()
        ..color = const Color(0xFFB1B1AC)
        ..strokeWidth = 1.4 * scale
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset((23 + i * 6) * scale, 25 * scale),
          Offset((21 + i * 6) * scale, 39 * scale),
          groove,
        );
      }
      canvas.drawCircle(
        Offset(44 * scale, 21 * scale),
        2 * scale,
        Paint()..color = const Color(0xFFE4E1D7),
      );
    } else if (type == 'oil') {
      final bottle = Path()
        ..moveTo(26 * scale, 16 * scale)
        ..lineTo(40 * scale, 16 * scale)
        ..lineTo(40 * scale, 23 * scale)
        ..lineTo(47 * scale, 28 * scale)
        ..lineTo(50 * scale, 51 * scale)
        ..quadraticBezierTo(49 * scale, 55 * scale, 45 * scale, 55 * scale)
        ..lineTo(20 * scale, 55 * scale)
        ..quadraticBezierTo(17 * scale, 54 * scale, 18 * scale, 50 * scale)
        ..lineTo(21 * scale, 29 * scale)
        ..lineTo(27 * scale, 24 * scale)
        ..close();
      canvas.drawPath(bottle.shift(Offset(0, 3 * scale)), shadow);
      canvas.drawPath(
        bottle,
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFFE34A25), Color(0xFFA91C18)],
              ).createShader(
                Rect.fromLTWH(18 * scale, 15 * scale, 33 * scale, 42 * scale),
              ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(23 * scale, 34 * scale, 23 * scale, 12 * scale),
          Radius.circular(2 * scale),
        ),
        Paint()..color = const Color(0xFFF7E8D1),
      );
      final text = TextPainter(
        text: TextSpan(
          text: 'AHM',
          style: TextStyle(
            color: const Color(0xFF282828),
            fontSize: 5 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(29 * scale, 37 * scale));
      canvas.drawRect(
        Rect.fromLTWH(28 * scale, 11 * scale, 10 * scale, 6 * scale),
        Paint()..color = const Color(0xFF242628),
      );
    } else if (type == 'filter') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 18 * scale, 34 * scale, 34 * scale),
          Radius.circular(7 * scale),
        ),
        Paint()..color = const Color(0xFFE4E0D5),
      );
      final pleat = Paint()
        ..color = const Color(0xFF85847E)
        ..strokeWidth = 2 * scale;
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(
          Offset((21 + i * 5) * scale, 21 * scale),
          Offset((21 + i * 5) * scale, 49 * scale),
          pleat,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 17 * scale, 34 * scale, 5 * scale),
          Radius.circular(3 * scale),
        ),
        dark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 48 * scale, 34 * scale, 5 * scale),
          Radius.circular(3 * scale),
        ),
        dark,
      );
    } else if (type == 'battery') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 21 * scale, 34 * scale, 32 * scale),
          Radius.circular(5 * scale),
        ),
        dark,
      );
      canvas.drawRect(
        Rect.fromLTWH(24 * scale, 16 * scale, 7 * scale, 6 * scale),
        Paint()..color = const Color(0xFFC9C8C0),
      );
      canvas.drawRect(
        Rect.fromLTWH(38 * scale, 16 * scale, 7 * scale, 6 * scale),
        Paint()..color = const Color(0xFFC9C8C0),
      );
      canvas.drawLine(
        Offset(27 * scale, 32 * scale),
        Offset(41 * scale, 32 * scale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2 * scale,
      );
      canvas.drawLine(
        Offset(34 * scale, 25 * scale),
        Offset(34 * scale, 39 * scale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2 * scale,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24 * scale, 14 * scale, 20 * scale, 7 * scale),
          Radius.circular(2 * scale),
        ),
        dark,
      );
      canvas.drawOval(
        Rect.fromLTWH(20 * scale, 19 * scale, 28 * scale, 34 * scale),
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFFFFE7A3), Color(0xFFE4A947)],
              ).createShader(
                Rect.fromLTWH(20 * scale, 19 * scale, 28 * scale, 34 * scale),
              ),
      );
      canvas.drawOval(
        Rect.fromLTWH(27 * scale, 27 * scale, 14 * scale, 18 * scale),
        Paint()..color = const Color(0xFFFFF5D7),
      );
    }
    canvas.drawCircle(
      Offset(center.dx + 20 * scale, center.dy + 23 * scale),
      1.3 * scale,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
  }

  @override
  bool shouldRepaint(covariant PartPainter oldDelegate) =>
      oldDelegate.type != type;
}
