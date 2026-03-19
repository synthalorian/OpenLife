import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/glucose.dart';

/// Simple glucose trend chart
class GlucoseChart extends StatelessWidget {
  final List<GlucoseReading> readings;
  final GlucoseTargets targets;

  const GlucoseChart({
    super.key,
    required this.readings,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return _buildEmptyChart(context);
    }

    // Sort readings by timestamp
    final sortedReadings = List<GlucoseReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
        painter: _GlucoseChartPainter(
          readings: sortedReadings,
          targets: targets,
        ),
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
          'No data to display',
          style: SynthwaveTextStyles.bodySmall(context),
        ),
      ),
    );
  }
}

class _GlucoseChartPainter extends CustomPainter {
  final List<GlucoseReading> readings;
  final GlucoseTargets targets;

  _GlucoseChartPainter({
    required this.readings,
    required this.targets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final minGlucose = 40.0;
    final maxGlucose = 300.0;
    final glucoseRange = maxGlucose - minGlucose;

    // Draw target range band
    final targetLowY = size.height - ((targets.postMealLow - minGlucose) / glucoseRange * size.height);
    final targetHighY = size.height - ((targets.postMealHigh - minGlucose) / glucoseRange * size.height);

    final targetPaint = Paint()
      ..color = SynthwaveColors.neonGreen.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, targetHighY, size.width, targetLowY - targetHighY),
      targetPaint,
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = SynthwaveColors.gridLine
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw glucose line
    final linePaint = Paint()
      ..color = SynthwaveColors.neonPink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < readings.length; i++) {
      final x = (i / (readings.length - 1)) * size.width;
      final y = size.height - ((readings[i].valueMgDl - minGlucose) / glucoseRange * size.height);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = SynthwaveColors.neonCyan
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y-axis labels
    final yLabels = ['300', '200', '100', '40'];
    for (int i = 0; i < yLabels.length; i++) {
      final y = (size.height / 3) * i;
      textPainter.text = TextSpan(
        text: yLabels[i],
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
