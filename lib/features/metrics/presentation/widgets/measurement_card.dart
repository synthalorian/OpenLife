import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/body_metrics.dart';

/// Card displaying a body measurement
class MeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;

  const MeasurementCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SynthwaveColors.neonCyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              measurement.weightKg?.toStringAsFixed(1) ?? '--',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: SynthwaveColors.neonCyan,
              ),
            ),
          ),
        ),
        title: Text(
          _formatDate(measurement.date),
          style: SynthwaveTextStyles.bodyMedium(context),
        ),
        subtitle: Text(
          '${measurement.measurementCount} measurements',
          style: SynthwaveTextStyles.bodySmall(context),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildMeasurementRow('Weight', measurement.weightKg, 'kg'),
                _buildMeasurementRow('Body Fat', measurement.bodyFatPercent, '%'),
                _buildMeasurementRow('Chest', measurement.chestCm, 'cm'),
                _buildMeasurementRow('Waist', measurement.waistCm, 'cm'),
                _buildMeasurementRow('Hips', measurement.hipsCm, 'cm'),
                _buildMeasurementRow('Left Arm', measurement.leftArmCm, 'cm'),
                _buildMeasurementRow('Right Arm', measurement.rightArmCm, 'cm'),
                _buildMeasurementRow('Left Thigh', measurement.leftThighCm, 'cm'),
                _buildMeasurementRow('Right Thigh', measurement.rightThighCm, 'cm'),
                if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    measurement.notes!,
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double? value, String unit) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: SynthwaveColors.chrome.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              color: SynthwaveColors.chrome,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final measurementDate = DateTime(date.year, date.month, date.day);

    if (measurementDate == today) return 'Today';
    if (measurementDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
