import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

class ChartPanel extends StatelessWidget {
  final String title;
  final List<num> values;
  const ChartPanel({super.key, required this.title, required this.values});
  @override
  Widget build(BuildContext c) => CardBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: ChartPainter(values: values),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${values.length} catatan lokal · data demo',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class ChartPainter extends CustomPainter {
  final List<num> values;
  ChartPainter({required this.values});
  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..color = AppColors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      c.drawLine(
        Offset(0, s.height * i / 5),
        Offset(s.width, s.height * i / 5),
        grid,
      );
    }
    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final points = values
        .map(
          (value) => maxValue == minValue
              ? .5
              : .88 -
                    ((value.toDouble() - minValue) / (maxValue - minValue)) *
                        .76,
        )
        .toList();
    final path = Path()..moveTo(10, s.height * points[0]);
    for (var i = 1; i < points.length; i++) {
      final x = 10 + (s.width - 20) * i / (points.length - 1);
      path.lineTo(x, s.height * points[i]);
    }
    c.drawPath(path, line);
    for (var i = 0; i < points.length; i++) {
      final x = 10 + (s.width - 20) * i / (points.length - 1);
      c.drawCircle(
        Offset(x, s.height * points[i]),
        5,
        Paint()..color = AppColors.red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
}
