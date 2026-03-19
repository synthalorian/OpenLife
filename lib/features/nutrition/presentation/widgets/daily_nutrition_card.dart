import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../nutrition_providers.dart';

/// Daily nutrition summary card
class DailyNutritionCard extends ConsumerWidget {
  final DateTime date;

  const DailyNutritionCard({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(dailyNutritionProvider(date));
    final goalsAsync = ref.watch(nutritionGoalsProvider);

    return nutritionAsync.when(
      data: (nutrition) => goalsAsync.when(
        data: (goals) => _buildCard(context, nutrition, goals),
        loading: () => const _LoadingCard(),
        error: (_, __) => const _LoadingCard(),
      ),
      loading: () => const _LoadingCard(),
      error: (_, __) => const _LoadingCard(),
    );
  }

  Widget _buildCard(BuildContext context, dynamic nutrition, dynamic goals) {
    final calPercent = (nutrition.calories / goals.calories * 100).clamp(0, 100);
    final proteinPercent = (nutrition.protein / goals.protein * 100).clamp(0, 100);
    final carbsPercent = (nutrition.carbs / goals.carbs * 100).clamp(0, 100);
    final fatPercent = (nutrition.fat / goals.fat * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SynthwaveColors.neonPink.withOpacity(0.2),
            SynthwaveColors.neonPurple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${nutrition.calories.toInt()}',
                    style: SynthwaveTextStyles.displayMedium(context),
                  ),
                  Text(
                    '/ ${goals.calories.toInt()} kcal',
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                ],
              ),
              _buildCircularProgress(
                calPercent / 100,
                SynthwaveColors.neonPink,
                '${calPercent.toInt()}%',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMacroRow('Protein', nutrition.protein, goals.protein, proteinPercent, SynthwaveColors.neonCyan),
          const SizedBox(height: 8),
          _buildMacroRow('Carbs', nutrition.carbs, goals.carbs, carbsPercent, SynthwaveColors.neonYellow),
          const SizedBox(height: 8),
          _buildMacroRow('Fat', nutrition.fat, goals.fat, fatPercent, SynthwaveColors.neonOrange),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(double value, Color color, String label) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: SynthwaveColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double current, double goal, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            Text(
              '${current.toInt()}g / ${goal.toInt()}g',
              style: TextStyle(color: SynthwaveColors.chrome.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            backgroundColor: SynthwaveColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
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
