import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/synthwave_theme.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../data/models/body_metrics.dart';
import 'metrics_providers.dart';
import 'widgets/weight_chart.dart';
import 'widgets/add_measurement_dialog.dart';
import 'widgets/measurement_card.dart';

/// Body metrics screen
class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BODY METRICS',
                style: SynthwaveTextStyles.displayLarge(context),
              ),
              const SizedBox(height: 16),

              // Current weight card
              _buildCurrentWeightCard(context, ref),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context, ref),
              const SizedBox(height: 24),

              // Weight chart
              Text(
                'WEIGHT TREND',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              _buildWeightChart(context, ref),
              const SizedBox(height: 24),

              // Recent measurements
              Text(
                'RECENT LOGS',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              _buildRecentMeasurements(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeightCard(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestMeasurementProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final bmiAsync = ref.watch(bmiProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SynthwaveColors.neonCyan.withOpacity(0.2),
            SynthwaveColors.neonBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: latestAsync.when(
        data: (measurement) => profileAsync.when(
          data: (profile) => _buildWeightContent(context, measurement, profile, bmiAsync.value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildNoWeightState(context),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildNoWeightState(context),
      ),
    );
  }

  Widget _buildWeightContent(BuildContext context, BodyMeasurement? measurement, UserProfile profile, double? bmi) {
    final weightDisplay = measurement?.weightKg != null
        ? profile.convertWeightToDisplay(measurement!.weightKg!)
        : null;
    final weightUnit = profile.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';

    return Column(
      children: [
        // Main weight display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weightDisplay?.toStringAsFixed(1) ?? '--',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: SynthwaveColors.neonCyan,
              ),
            ),
            const SizedBox(width: 8),
              Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                weightUnit,
                style: SynthwaveTextStyles.bodyLarge(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          measurement != null ? 'Last logged ${_formatDate(measurement.date)}' : 'No weight logged',
          style: SynthwaveTextStyles.bodySmall(context),
        ),

        if (bmi != null) ...[
          const SizedBox(height: 16),
          const Divider(color: SynthwaveColors.gridLine),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('BMI', bmi.toStringAsFixed(1), _getBMIColor(bmi)),
              _buildStatItem('Category', BodyMeasurement.getBMICategory(bmi), SynthwaveColors.chrome),
              if (measurement?.bodyFatPercent != null)
                _buildStatItem('Body Fat', '${measurement!.bodyFatPercent!.toStringAsFixed(1)}%', SynthwaveColors.neonPink),
            ],
          ),
        ],

        // Target weight
        if (profile.targetWeightKg != null && weightDisplay != null) ...[
          const SizedBox(height: 16),
          _buildTargetProgress(weightDisplay, profile.convertWeightToDisplay(profile.targetWeightKg!), weightUnit),
        ],
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: SynthwaveColors.chrome.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetProgress(double current, double target, String unit) {
    final difference = current - target;
    final isOver = difference > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isOver ? Icons.arrow_upward : Icons.arrow_downward,
          color: isOver ? SynthwaveColors.neonOrange : SynthwaveColors.neonGreen,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${difference.abs().toStringAsFixed(1)} $unit ${isOver ? 'above' : 'below'} target',
          style: TextStyle(
            color: isOver ? SynthwaveColors.neonOrange : SynthwaveColors.neonGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildNoWeightState(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.monitor_weight,
          size: 48,
          color: SynthwaveColors.chrome.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'No weight logged yet',
          style: SynthwaveTextStyles.bodyMedium(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap "Log Weight" to get started',
          style: SynthwaveTextStyles.bodySmall(context),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddWeightDialog(context, ref),
            icon: const Icon(Icons.scale, size: 20),
            label: const Text('LOG WEIGHT'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAddMeasurementDialog(context, ref),
            icon: const Icon(Icons.straighten, size: 20),
            label: const Text('ADD MEASUREMENTS'),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(weightHistoryProvider(30));

    return measurementsAsync.when(
      data: (measurements) => WeightChart(measurements: measurements),
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: SynthwaveColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: SynthwaveColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Error loading chart')),
      ),
    );
  }

  Widget _buildRecentMeasurements(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(allMeasurementsProvider);

    return measurementsAsync.when(
      data: (measurements) {
        if (measurements.isEmpty) {
          return _buildEmptyMeasurements(context);
        }

        return Column(
          children: measurements.take(5).map((m) => MeasurementCard(measurement: m)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading measurements'),
    );
  }

  Widget _buildEmptyMeasurements(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No measurements logged',
            style: SynthwaveTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddMeasurementDialog(
        weightOnly: true,
        onAdd: (measurement) {
          ref.read(addMeasurementProvider)(measurement);
        },
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddMeasurementDialog(
        weightOnly: false,
        onAdd: (measurement) {
          ref.read(addMeasurementProvider)(measurement);
        },
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return SynthwaveColors.neonCyan;
    if (bmi < 25) return SynthwaveColors.neonGreen;
    if (bmi < 30) return SynthwaveColors.neonYellow;
    return SynthwaveColors.neonOrange;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final measurementDate = DateTime(date.year, date.month, date.day);

    if (measurementDate == today) return 'today';
    if (measurementDate == today.subtract(const Duration(days: 1))) return 'yesterday';

    return '${date.month}/${date.day}';
  }
}
