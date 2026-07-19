import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/freegrid_theme.dart';

/// Hero 内的 Silverline 趋势线：无坐标、无填充，只强调当前终点。
class DashboardSparkline extends StatelessWidget {
  const DashboardSparkline({required this.values, super.key});

  static const paintKey = ValueKey('dashboard-sparkline-paint');

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: paintKey,
      painter: DashboardSparklinePainter(
        values: values,
        color: context.fg.skyDeep,
      ),
    );
  }
}

class DashboardSparklinePainter extends CustomPainter {
  const DashboardSparklinePainter({required this.values, required this.color});

  static const strokeWidth = 1.2;
  static const endDotDiameter = 5.0;

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = math.max(1.0, maxValue - minValue);
    final step = size.width / (values.length - 1);
    const verticalPadding = 4.0;

    final path = Path();
    for (var i = 0; i < values.length; i += 1) {
      final x = step * i;
      final normalized = (values[i] - minValue) / span;
      final y =
          size.height -
          verticalPadding -
          normalized * (size.height - 2 * verticalPadding);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    final normalizedLast = (values.last - minValue) / span;
    final lastY =
        size.height -
        verticalPadding -
        normalizedLast * (size.height - 2 * verticalPadding);
    canvas.drawCircle(
      Offset(size.width, lastY),
      endDotDiameter / 2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant DashboardSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
