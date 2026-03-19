import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/glucose.dart';

/// Card displaying a glucose reading
class GlucoseReadingCard extends StatelessWidget {
  final GlucoseReading reading;
  final VoidCallback? onDelete;

  const GlucoseReadingCard({
    super.key,
    required this.reading,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getClassificationColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              reading.valueMgDl.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getClassificationColor(),
              ),
            ),
          ),
        ),
        title: Text(
          _formatContext(reading.context),
          style: SynthwaveTextStyles.bodyMedium(context),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTime(reading.timestamp),
              style: SynthwaveTextStyles.bodySmall(context),
            ),
            if (reading.notes != null && reading.notes!.isNotEmpty)
              Text(
                reading.notes!,
                style: SynthwaveTextStyles.bodySmall(context).copyWith(
                  color: SynthwaveColors.chrome.withOpacity(0.5),
                ),
              ),
          ],
        ),
        trailing: _buildClassificationBadge(),
      ),
    );
  }

  Widget _buildClassificationBadge() {
    final classification = reading.classification;
    final color = _getClassificationColor();
    final label = _getClassificationLabel(classification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getClassificationColor() {
    switch (reading.classification) {
      case GlucoseClassification.low:
        return SynthwaveColors.neonPink;
      case GlucoseClassification.normal:
        return SynthwaveColors.neonGreen;
      case GlucoseClassification.elevated:
        return SynthwaveColors.neonYellow;
      case GlucoseClassification.high:
        return SynthwaveColors.neonOrange;
      case GlucoseClassification.veryHigh:
        return SynthwaveColors.error;
    }
  }

  String _getClassificationLabel(GlucoseClassification classification) {
    switch (classification) {
      case GlucoseClassification.low:
        return 'LOW';
      case GlucoseClassification.normal:
        return 'NORMAL';
      case GlucoseClassification.elevated:
        return 'ELEVATED';
      case GlucoseClassification.high:
        return 'HIGH';
      case GlucoseClassification.veryHigh:
        return 'VERY HIGH';
    }
  }

  String _formatContext(GlucoseContext ctx) {
    switch (ctx) {
      case GlucoseContext.fasting:
        return 'Fasting';
      case GlucoseContext.preMeal:
        return 'Pre-Meal';
      case GlucoseContext.postMeal:
        return 'Post-Meal';
      case GlucoseContext.bedtime:
        return 'Bedtime';
      case GlucoseContext.general:
        return 'General';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}
