import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/food.dart';
import '../../../../core/utils/string_extensions.dart';

/// Meal card widget
class MealCard extends StatelessWidget {
  final MealLog meal;

  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMealType(meal.mealType),
                  style: SynthwaveTextStyles.labelLarge(context),
                ),
                Text(
                  '${meal.totalCalories.toInt()} kcal',
                  style: TextStyle(
                    color: SynthwaveColors.neonCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...meal.foods.map((food) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(food.foodName),
                  ),
                  Text(
                    '${food.quantity.toStringAsFixed(1)} ${_formatUnit(food.unit)}',
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${food.calories.toInt()}',
                    style: TextStyle(color: SynthwaveColors.chrome.withOpacity(0.7)),
                  ),
                ],
              ),
            )),
            if (meal.foods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildMacroBadge('P', meal.totalProtein, SynthwaveColors.neonCyan),
                  const SizedBox(width: 8),
                  _buildMacroBadge('C', meal.totalCarbs, SynthwaveColors.neonYellow),
                  const SizedBox(width: 8),
                  _buildMacroBadge('F', meal.totalFat, SynthwaveColors.neonOrange),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toInt()}g',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatMealType(MealType type) {
    return type.name.capitalize();
  }

  String _formatUnit(ServingUnit unit) {
    switch (unit) {
      case ServingUnit.gram:
        return 'g';
      case ServingUnit.milliliter:
        return 'ml';
      case ServingUnit.piece:
        return 'pc';
      case ServingUnit.serving:
        return 'srv';
      default:
        return unit.name;
    }
  }
}
