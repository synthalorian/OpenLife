import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/food.dart';
import '../nutrition_providers.dart';

/// Water tracker widget
class WaterTracker extends ConsumerWidget {
  final DateTime date;

  const WaterTracker({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterIntakeProvider(date));
    final goalsAsync = ref.watch(nutritionGoalsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: SynthwaveColors.neonBlue),
              const SizedBox(width: 8),
              Text('WATER', style: SynthwaveTextStyles.labelLarge(context)),
            ],
          ),
          const SizedBox(height: 12),
          waterAsync.when(
            data: (water) => goalsAsync.when(
              data: (goals) => _buildWaterContent(context, ref, water, goals.water),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error'),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterContent(BuildContext context, WidgetRef ref, double water, double goal) {
    final percent = (water / goal * 100).clamp(0, 100);
    final glasses = (water / 250).floor();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(water / 1000).toStringAsFixed(1)}L',
              style: SynthwaveTextStyles.displaySmall(context),
            ),
            Text(
              '$glasses glasses',
              style: SynthwaveTextStyles.bodySmall(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 12,
            backgroundColor: SynthwaveColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(SynthwaveColors.neonBlue),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addWater(ref, 250),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('250ml'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addWater(ref, 500),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('500ml'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addWater(WidgetRef ref, double amount) {
    // Use the provider to add water
    ref.read(addWaterProvider)(amount);
    ref.invalidate(waterIntakeProvider(date));
  }
}
