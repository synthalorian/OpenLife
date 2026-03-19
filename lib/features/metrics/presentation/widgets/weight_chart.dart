import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/body_metrics.dart';

/// Weight trend chart
class WeightChart extends StatelessWidget {
  final List<BodyMeasurement> measurements;

  const WeightChart({
    super.key,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty || !measurements.any((m) => m.weightKg != null)) {
      return _buildEmptyChart(context);
    }

    // Sort by date (oldest first for chart)
    final sorted = List<BodyMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weights = sorted.where((m) => m.weightKg != null).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 170),
        painter: _WeightChartPainter(measurements: weights),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Center(
        child: Text(
          'Not enough data',
          style: SynthwaveTextStyles.bodySmall(context),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<BodyMeasurement> measurements;

  _WeightChartPainter({required this.measurements});

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;

    // Find min/max weight for scaling
    final weights = measurements.map((m) => m.weightKg!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b) - 2;
    final maxWeight = weights.reduce((a, b) => a > b ? a : b) + 2;
    final weightRange = maxWeight - minWeight;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = SynthwaveColors.gridLine
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw weight line
    final linePaint = Paint()
      ..color = SynthwaveColors.neonCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = SynthwaveColors.neonCyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < measurements.length; i++) {
      final x = (i / (measurements.length - 1)) * size.width;
      final y = size.height - ((measurements[i].weightKg! - minWeight) / weightRange * size.height);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      // Draw fill
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);

      // Draw line
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw points
      final pointPaint = Paint()
        ..color = SynthwaveColors.neonCyan
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }

    // Draw Y-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final yLabels = [maxWeight, (maxWeight + minWeight) / 2, minWeight];
    for (int i = 0; i < yLabels.length; i++) {
      final y = i == 0 ? 0.0 : (i == 1 ? size.height / 2 : size.height);
      textPainter.text = TextSpan(
        text: yLabels[i].toStringAsFixed(1),
        style: TextStyle(
          color: SynthwaveColors.chrome.withOpacity(0.5),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
