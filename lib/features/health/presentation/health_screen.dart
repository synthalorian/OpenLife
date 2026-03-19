import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/synthwave_theme.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../data/models/glucose.dart';
import 'health_providers.dart';
import 'widgets/glucose_add_dialog.dart';
import 'widgets/glucose_chart.dart';
import 'widgets/glucose_reading_card.dart';

/// Main health screen with glucose logging
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(glucoseSelectedDateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HEALTH',
                style: SynthwaveTextStyles.displayLarge(context),
              ),
              const SizedBox(height: 16),

              // Date selector
              _buildDateSelector(context, ref, selectedDate),
              const SizedBox(height: 24),

              // Daily glucose summary
              _buildDailySummary(context, ref, selectedDate),
              const SizedBox(height: 24),

              // Quick add buttons
              Text(
                'LOG GLUCOSE',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              _buildQuickAddButtons(context, ref),
              const SizedBox(height: 24),

              // Today's readings
              Text(
                'READINGS',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              _buildReadingsList(context, ref, selectedDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(glucoseSelectedDateProvider.notifier).state =
                  selectedDate.subtract(const Duration(days: 1));
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  ref.read(glucoseSelectedDateProvider.notifier).state = date;
                }
              },
              child: Text(
                isToday ? 'Today' : _formatDate(selectedDate),
                textAlign: TextAlign.center,
                style: SynthwaveTextStyles.bodyLarge(context),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: selectedDate.day == now.day &&
                    selectedDate.month == now.month &&
                    selectedDate.year == now.year
                ? null
                : () {
                    ref.read(glucoseSelectedDateProvider.notifier).state =
                        selectedDate.add(const Duration(days: 1));
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(BuildContext context, WidgetRef ref, DateTime date) {
    final summaryAsync = ref.watch(dailyGlucoseSummaryProvider(date));
    final targetsAsync = ref.watch(glucoseTargetsProvider);

    return summaryAsync.when(
      data: (summary) => targetsAsync.when(
        data: (targets) => _buildSummaryCard(context, summary, targets),
        loading: () => const _LoadingCard(),
        error: (_, __) => const _LoadingCard(),
      ),
      loading: () => const _LoadingCard(),
      error: (_, __) => const _LoadingCard(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, DailyGlucoseSummary summary, GlucoseTargets targets) {
    final avg = summary.average;
    final min = summary.min;
    final max = summary.max;
    final timeInRange = summary.timeInRange;
    final readings = summary.readings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SynthwaveColors.neonPurple.withOpacity(0.2),
            SynthwaveColors.neonBlue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Column(
        children: [
          // Average glucose
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avg.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getGlucoseColor(avg),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targets.displayUnit == GlucoseUnit.mgDl ? 'mg/dL' : 'mmol/L',
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                  Text(
                    'Average',
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Min', min.toStringAsFixed(0), SynthwaveColors.neonCyan),
              _buildStat('Max', max.toStringAsFixed(0), SynthwaveColors.neonPink),
              _buildStat('In Range', '${timeInRange.toStringAsFixed(0)}%', SynthwaveColors.neonGreen),
              _buildStat('Readings', readings.toString(), SynthwaveColors.neonYellow),
            ],
          ),
          const SizedBox(height: 16),

          // Time in range bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time in Range', style: SynthwaveTextStyles.bodySmall(context)),
                  Text('${timeInRange.toStringAsFixed(0)}%', style: TextStyle(color: SynthwaveColors.neonGreen)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: timeInRange / 100,
                  minHeight: 8,
                  backgroundColor: SynthwaveColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(SynthwaveColors.neonGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
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
            fontSize: 10,
            color: SynthwaveColors.chrome.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButtons(BuildContext context, WidgetRef ref) {
    final contexts = [
      (GlucoseContext.fasting, 'Fasting', Icons.wb_sunny),
      (GlucoseContext.preMeal, 'Pre-Meal', Icons.restaurant_menu),
      (GlucoseContext.postMeal, 'Post-Meal', Icons.fastfood),
      (GlucoseContext.bedtime, 'Bedtime', Icons.bedtime),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: contexts.map((ctx) {
        return ElevatedButton.icon(
          onPressed: () => _showAddDialog(context, ref, ctx.$1),
          icon: Icon(ctx.$3, size: 20),
          label: Text(ctx.$2),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReadingsList(BuildContext context, WidgetRef ref, DateTime date) {
    final summaryAsync = ref.watch(dailyGlucoseSummaryProvider(date));

    return summaryAsync.when(
      data: (summary) {
        if (summary.readings.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: summary.readings.map((reading) => 
            GlucoseReadingCard(reading: reading)
          ).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading readings'),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            Icons.bloodtype,
            size: 48,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No readings logged',
            style: SynthwaveTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a button above to log your glucose',
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, GlucoseContext defaultContext) {
    showDialog(
      context: context,
      builder: (context) => GlucoseAddDialog(
        defaultContext: defaultContext,
        onAdd: (value, context, notes) {
          ref.read(quickAddGlucoseProvider)(value, context, notes);
        },
      ),
    );
  }

  Color _getGlucoseColor(double valueMgDl) {
    if (valueMgDl < 70) return SynthwaveColors.neonPink; // Low
    if (valueMgDl < 100) return SynthwaveColors.neonGreen; // Normal
    if (valueMgDl < 126) return SynthwaveColors.neonYellow; // Elevated
    if (valueMgDl < 200) return SynthwaveColors.neonOrange; // High
    return SynthwaveColors.error; // Very high
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
