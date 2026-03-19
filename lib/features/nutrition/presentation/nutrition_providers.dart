import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/food.dart';
import '../../../data/services/database_service.dart';

/// Selected date for nutrition tracking
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Nutrition repositories
final foodRepositoryProvider = FutureProvider<FoodRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return FoodRepository(isar);
});

final mealLogRepositoryProvider = FutureProvider<MealLogRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return MealLogRepository(isar);
});

final nutritionGoalsRepositoryProvider = FutureProvider<NutritionGoalsRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return NutritionGoalsRepository(isar);
});

final waterLogRepositoryProvider = FutureProvider<WaterLogRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return WaterLogRepository(isar);
});

/// All foods
final allFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repo = await ref.watch(foodRepositoryProvider.future);
  return await repo.getAll();
});

/// Favorite foods
final favoriteFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repo = await ref.watch(foodRepositoryProvider.future);
  return await repo.getFavorites();
});

/// Search foods
final foodSearchProvider = FutureProvider.family<List<Food>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final repo = await ref.watch(foodRepositoryProvider.future);
    return await repo.search(query);
  },
);

/// Daily nutrition summary
final dailyNutritionProvider = FutureProvider.family<DailyNutrition, DateTime>(
  (ref, date) async {
    final repo = await ref.watch(mealLogRepositoryProvider.future);
    return await repo.getDailyNutrition(date);
  },
);

/// Meals for selected date
final mealsForDateProvider = FutureProvider.family<List<MealLog>, DateTime>(
  (ref, date) async {
    final repo = await ref.watch(mealLogRepositoryProvider.future);
    return await repo.getMealsForDate(date);
  },
);

/// Nutrition goals
final nutritionGoalsProvider = FutureProvider<NutritionGoals>((ref) async {
  final repo = await ref.watch(nutritionGoalsRepositoryProvider.future);
  return await repo.getGoals();
});

/// Water intake for selected date
final waterIntakeProvider = FutureProvider.family<double, DateTime>(
  (ref, date) async {
    final repo = await ref.watch(waterLogRepositoryProvider.future);
    return await repo.getWaterForDate(date);
  },
);

/// Active meal logging (for adding foods to a meal)
final activeMealProvider = StateNotifierProvider<ActiveMealNotifier, MealLog?>(
  (ref) => ActiveMealNotifier(),
);

class ActiveMealNotifier extends StateNotifier<MealLog?> {
  ActiveMealNotifier() : super(null);

  void startMeal(MealType type, DateTime date) {
    state = MealLog(
      uuid: const Uuid().v4(),
      date: date,
      mealType: type,
    );
  }

  void addFood(Food food, double quantity, ServingUnit unit) {
    if (state == null) return;

    final nutrition = food.getNutritionForQuantity(quantity, unit);
    final loggedFood = LoggedFood()
      ..foodUuid = food.uuid
      ..foodName = food.name
      ..quantity = quantity
      ..unit = unit
      ..calories = nutrition['calories'] ?? 0
      ..protein = nutrition['protein'] ?? 0
      ..carbs = nutrition['carbs'] ?? 0
      ..fat = nutrition['fat'] ?? 0
      ..fiber = nutrition['fiber'] ?? 0;

    state = MealLog(
      uuid: state!.uuid,
      date: state!.date,
      mealType: state!.mealType,
      foods: [...state!.foods, loggedFood],
      notes: state!.notes,
    );
  }

  void removeFood(int index) {
    if (state == null || index >= state!.foods.length) return;

    final foods = [...state!.foods];
    foods.removeAt(index);

    state = MealLog(
      uuid: state!.uuid,
      date: state!.date,
      mealType: state!.mealType,
      foods: foods,
      notes: state!.notes,
    );
  }

  Future<void> saveMeal() async {
    if (state == null) return;

    final isar = await DatabaseService.instance;
    final repo = MealLogRepository(isar);
    await repo.create(state!);
    state = null;
  }

  void cancelMeal() {
    state = null;
  }
}

/// Quick add water
final addWaterProvider = Provider<Function>((ref) {
  return (double amount) async {
    final isar = await DatabaseService.instance;
    final repo = WaterLogRepository(isar);
    await repo.addWater(amount);
    // Invalidate water provider
    ref.invalidate(waterIntakeProvider);
  };
});
