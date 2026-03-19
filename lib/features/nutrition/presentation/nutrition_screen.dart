import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/synthwave_theme.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../data/models/food.dart';
import 'nutrition_providers.dart';
import 'widgets/daily_nutrition_card.dart';
import 'widgets/food_picker_sheet.dart';
import 'widgets/meal_card.dart';
import 'widgets/water_tracker.dart';

/// Main nutrition screen
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUTRITION',
                style: SynthwaveTextStyles.displayLarge(context),
              ),
              const SizedBox(height: 16),

              // Date selector
              _buildDateSelector(context, ref, selectedDate),
              const SizedBox(height: 24),

              // Daily nutrition summary
              DailyNutritionCard(date: selectedDate),
              const SizedBox(height: 24),

              // Water tracker
              WaterTracker(date: selectedDate),
              const SizedBox(height: 24),

              // Meals
              Text(
                'MEALS',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              _buildMealButtons(context, ref, selectedDate),
              const SizedBox(height: 24),

              // Today's meals
              _buildTodaysMeals(context, ref, selectedDate),
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
              ref.read(selectedDateProvider.notifier).state =
                  selectedDate.subtract(const Duration(days: 1));
            },
          ),
          Expanded(
            child: Text(
              isToday ? 'Today' : _formatDate(selectedDate),
              textAlign: TextAlign.center,
              style: SynthwaveTextStyles.bodyLarge(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state =
                  selectedDate.add(const Duration(days: 1));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealButtons(BuildContext context, WidgetRef ref, DateTime date) {
    final meals = [
      (MealType.breakfast, Icons.breakfast_dining, 'Breakfast'),
      (MealType.lunch, Icons.lunch_dining, 'Lunch'),
      (MealType.dinner, Icons.dinner_dining, 'Dinner'),
      (MealType.snack, Icons.cookie, 'Snack'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: meals.map((meal) {
        return ElevatedButton.icon(
          onPressed: () => _showAddFoodDialog(context, ref, meal.$1, date),
          icon: Icon(meal.$2, size: 20),
          label: Text(meal.$3),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodaysMeals(BuildContext context, WidgetRef ref, DateTime date) {
    final mealsAsync = ref.watch(mealsForDateProvider(date));

    return mealsAsync.when(
      data: (meals) {
        if (meals.isEmpty) {
          return _buildEmptyMeals(context);
        }

        return Column(
          children: meals.map((meal) => MealCard(meal: meal)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading meals'),
    );
  }

  Widget _buildEmptyMeals(BuildContext context) {
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
            Icons.restaurant,
            size: 48,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No meals logged yet',
            style: SynthwaveTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a meal button above to add food',
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref, MealType type, DateTime date) {
    ref.read(activeMealProvider.notifier).startMeal(type, date);

    showModalBottomSheet(
      context: context,
      backgroundColor: SynthwaveColors.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return FoodPickerSheet(
            mealType: type,
            scrollController: scrollController,
            onComplete: () {
              Navigator.pop(context);
              ref.invalidate(mealsForDateProvider(date));
              ref.invalidate(dailyNutritionProvider(date));
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    return '${date.month}/${date.day}/${date.year}';
  }
}
