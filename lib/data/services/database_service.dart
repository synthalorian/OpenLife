import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/body_metrics.dart';
import '../models/exercise.dart';
import '../models/food.dart';
import '../models/glucose.dart';
import '../models/workout_log.dart';

/// Database service for Open Fit
class DatabaseService {
  static Isar? _instance;

  /// Get the Isar database instance
  static Future<Isar> get instance async {
    if (_instance == null) {
      await _init();
    }
    return _instance!;
  }

  /// Initialize the database
  static Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [
        BodyMeasurementSchema,
        UserProfileSchema,
        ExerciseSchema,
        FoodSchema,
        GlucoseReadingSchema,
        GlucoseTargetsSchema,
        MealLogSchema,
        NutritionGoalsSchema,
        WaterLogSchema,
        WorkoutLogSchema,
        PersonalRecordSchema,
      ],
      directory: dir.path,
    );

    // Populate default exercises and foods on first launch
    await _populateDefaultData();
  }

  /// Populate default data if the database is empty
  static Future<void> _populateDefaultData() async {
    final isar = _instance!;

    // Populate exercises
    final exerciseCount = await isar.exercises.count();
    if (exerciseCount == 0) {
      final exercises = getDefaultExercises();
      await isar.writeTxn(() async {
        await isar.exercises.putAll(exercises);
      });
    }

    // Populate foods
    final foodCount = await isar.foods.count();
    if (foodCount == 0) {
      final foods = getDefaultFoods();
      await isar.writeTxn(() async {
        await isar.foods.putAll(foods);
      });
    }

    // Create default nutrition goals if none exist
    final goalsCount = await isar.nutritionGoals.count();
    if (goalsCount == 0) {
      await isar.writeTxn(() async {
        await isar.nutritionGoals.put(NutritionGoals());
      });
    }
  }

  /// Close the database
  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}

/// Exercise repository
class ExerciseRepository {
  final Isar _isar;

  ExerciseRepository(this._isar);

  /// Get all exercises
  Future<List<Exercise>> getAll() async {
    return await _isar.exercises.where().findAll();
  }

  /// Get exercises by muscle group
  Future<List<Exercise>> getByMuscleGroup(MuscleGroup group) async {
    return await _isar.exercises
        .filter()
        .primaryMuscleGroupEqualTo(group)
        .findAll();
  }

  /// Get exercises by equipment
  Future<List<Exercise>> getByEquipment(Equipment equipment) async {
    return await _isar.exercises
        .filter()
        .equipmentEqualTo(equipment)
        .findAll();
  }

  /// Search exercises by name
  Future<List<Exercise>> search(String query) async {
    return await _isar.exercises
        .filter()
        .nameContains(query, caseSensitive: false)
        .findAll();
  }

  /// Get exercise by UUID
  Future<Exercise?> getByUuid(String uuid) async {
    return await _isar.exercises.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Add a custom exercise
  Future<void> add(Exercise exercise) async {
    exercise.isCustom = true;
    await _isar.writeTxn(() async {
      await _isar.exercises.put(exercise);
    });
  }

  /// Update an exercise
  Future<void> update(Exercise exercise) async {
    exercise.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.exercises.put(exercise);
    });
  }

  /// Delete an exercise (only custom ones)
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.exercises.delete(id);
    });
  }
}

/// Workout log repository
class WorkoutLogRepository {
  final Isar _isar;

  WorkoutLogRepository(this._isar);

  /// Get all workout logs
  Future<List<WorkoutLog>> getAll() async {
    return await _isar.workoutLogs.where().sortByStartTimeDesc().findAll();
  }

  /// Get recent workouts (last N)
  Future<List<WorkoutLog>> getRecent(int limit) async {
    return await _isar.workoutLogs
        .where()
        .sortByStartTimeDesc()
        .limit(limit)
        .findAll();
  }

  /// Get workout by UUID
  Future<WorkoutLog?> getByUuid(String uuid) async {
    return await _isar.workoutLogs.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Get workouts in date range
  Future<List<WorkoutLog>> getInDateRange(DateTime start, DateTime end) async {
    return await _isar.workoutLogs
        .filter()
        .startTimeBetween(start, end)
        .sortByStartTimeDesc()
        .findAll();
  }

  /// Get current workout in progress
  Future<WorkoutLog?> getWorkoutInProgress() async {
    return await _isar.workoutLogs
        .filter()
        .endTimeIsNull()
        .findFirst();
  }

  /// Create a new workout
  Future<void> create(WorkoutLog workout) async {
    await _isar.writeTxn(() async {
      await _isar.workoutLogs.put(workout);
    });
  }

  /// Update a workout
  Future<void> update(WorkoutLog workout) async {
    await _isar.writeTxn(() async {
      await _isar.workoutLogs.put(workout);
    });
  }

  /// Delete a workout
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.workoutLogs.delete(id);
    });
  }

  /// Get workout statistics
  Future<WorkoutStats> getStats() async {
    final workouts = await getAll();
    final completedWorkouts = workouts.where((w) => !w.isInProgress).toList();

    if (completedWorkouts.isEmpty) {
      return WorkoutStats.empty();
    }

    final totalWorkouts = completedWorkouts.length;
    final totalSets = completedWorkouts.fold(0, (sum, w) => sum + w.totalSets);
    final totalVolume = completedWorkouts.fold(0.0, (sum, w) => sum + w.totalVolume);
    final avgDuration = completedWorkouts.fold(0, (sum, w) => sum + w.durationMinutes) ~/ totalWorkouts;

    // Calculate streak
    int currentStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasWorkout = completedWorkouts.any((w) {
        final workoutDate = DateTime(
          w.startTime.year,
          w.startTime.month,
          w.startTime.day,
        );
        return workoutDate == checkDate;
      });

      if (hasWorkout) {
        currentStreak++;
      } else if (i > 0) {
        break;
      }
    }

    return WorkoutStats(
      totalWorkouts: totalWorkouts,
      totalSets: totalSets,
      totalVolume: totalVolume,
      averageWorkoutDuration: avgDuration,
      currentStreak: currentStreak,
    );
  }
}

/// Workout statistics
class WorkoutStats {
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;
  final int averageWorkoutDuration;
  final int currentStreak;

  const WorkoutStats({
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    required this.averageWorkoutDuration,
    required this.currentStreak,
  });

  factory WorkoutStats.empty() {
    return const WorkoutStats(
      totalWorkouts: 0,
      totalSets: 0,
      totalVolume: 0,
      averageWorkoutDuration: 0,
      currentStreak: 0,
    );
  }
}

/// Food repository
class FoodRepository {
  final Isar _isar;

  FoodRepository(this._isar);

  /// Get all foods
  Future<List<Food>> getAll() async {
    return await _isar.foods.where().findAll();
  }

  /// Get favorite foods
  Future<List<Food>> getFavorites() async {
    return await _isar.foods.filter().isFavoriteEqualTo(true).findAll();
  }

  /// Search foods by name
  Future<List<Food>> search(String query) async {
    return await _isar.foods
        .filter()
        .nameContains(query, caseSensitive: false)
        .or()
        .brandNameContains(query, caseSensitive: false)
        .findAll();
  }

  /// Get food by barcode
  Future<Food?> getByBarcode(String barcode) async {
    return await _isar.foods.filter().barcodeEqualTo(barcode).findFirst();
  }

  /// Get food by UUID
  Future<Food?> getByUuid(String uuid) async {
    return await _isar.foods.filter().uuidEqualTo(uuid).findFirst();
  }

  /// Add a custom food
  Future<void> add(Food food) async {
    food.isCustom = true;
    await _isar.writeTxn(() async {
      await _isar.foods.put(food);
    });
  }

  /// Toggle favorite
  Future<void> toggleFavorite(int id) async {
    await _isar.writeTxn(() async {
      final food = await _isar.foods.get(id);
      if (food != null) {
        food.isFavorite = !food.isFavorite;
        await _isar.foods.put(food);
      }
    });
  }
}

/// Meal log repository
class MealLogRepository {
  final Isar _isar;

  MealLogRepository(this._isar);

  /// Get meals for a specific date
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _isar.mealLogs
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .sortByMealType()
        .findAll();
  }

  /// Get meals in date range
  Future<List<MealLog>> getMealsInRange(DateTime start, DateTime end) async {
    return await _isar.mealLogs
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Create a meal log
  Future<void> create(MealLog meal) async {
    await _isar.writeTxn(() async {
      await _isar.mealLogs.put(meal);
    });
  }

  /// Update a meal log
  Future<void> update(MealLog meal) async {
    await _isar.writeTxn(() async {
      await _isar.mealLogs.put(meal);
    });
  }

  /// Delete a meal log
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.mealLogs.delete(id);
    });
  }

  /// Get daily nutrition totals
  Future<DailyNutrition> getDailyNutrition(DateTime date) async {
    final meals = await getMealsForDate(date);

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;

    for (final meal in meals) {
      calories += meal.totalCalories;
      protein += meal.totalProtein;
      carbs += meal.totalCarbs;
      fat += meal.totalFat;
      fiber += meal.totalFiber;
    }

    // Get water intake
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final waterLogs = await _isar.waterLogs
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findAll();
    final water = waterLogs.fold<double>(0, (sum, log) => sum + log.amount);

    return DailyNutrition(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      water: water,
    );
  }
}

/// Nutrition goals repository
class NutritionGoalsRepository {
  final Isar _isar;

  NutritionGoalsRepository(this._isar);

  /// Get current goals
  Future<NutritionGoals> getGoals() async {
    final goals = await _isar.nutritionGoals.where().findFirst();
    return goals ?? NutritionGoals();
  }

  /// Update goals
  Future<void> updateGoals(NutritionGoals goals) async {
    await _isar.writeTxn(() async {
      await _isar.nutritionGoals.put(goals);
    });
  }
}

/// Water log repository
class WaterLogRepository {
  final Isar _isar;

  WaterLogRepository(this._isar);

  /// Get water intake for date
  Future<double> getWaterForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logs = await _isar.waterLogs
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findAll();

    return logs.fold<double>(0, (sum, log) => sum + log.amount);
  }

  /// Add water
  Future<void> addWater(double amount) async {
    final now = DateTime.now();
    final log = WaterLog(
      date: DateTime(now.year, now.month, now.day),
      amount: amount,
    );

    await _isar.writeTxn(() async {
      await _isar.waterLogs.put(log);
    });
  }
}

/// Daily nutrition summary
class DailyNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double water;

  const DailyNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.water = 0,
  });
}

/// Glucose reading repository
class GlucoseRepository {
  final Isar _isar;

  GlucoseRepository(this._isar);

  /// Get readings for a specific date
  Future<List<GlucoseReading>> getReadingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _isar.glucoseReadings
        .filter()
        .timestampBetween(startOfDay, endOfDay)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Get readings in date range
  Future<List<GlucoseReading>> getReadingsInRange(DateTime start, DateTime end) async {
    return await _isar.glucoseReadings
        .filter()
        .timestampBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Get daily summary
  Future<DailyGlucoseSummary> getDailySummary(DateTime date) async {
    final readings = await getReadingsForDate(date);
    return DailyGlucoseSummary(
      date: DateTime(date.year, date.month, date.day),
      readings: readings,
    );
  }

  /// Add a reading
  Future<void> addReading(GlucoseReading reading) async {
    await _isar.writeTxn(() async {
      await _isar.glucoseReadings.put(reading);
    });
  }

  /// Delete a reading
  Future<void> deleteReading(int id) async {
    await _isar.writeTxn(() async {
      await _isar.glucoseReadings.delete(id);
    });
  }

  /// Get recent readings (last N)
  Future<List<GlucoseReading>> getRecentReadings(int limit) async {
    return await _isar.glucoseReadings
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  /// Get readings by context
  Future<List<GlucoseReading>> getReadingsByContext(GlucoseContext context, {DateTime? startDate, DateTime? endDate}) async {
    var query = _isar.glucoseReadings.filter().contextEqualTo(context);
    
    if (startDate != null && endDate != null) {
      query = query.timestampBetween(startDate, endDate);
    }
    
    return await query.sortByTimestampDesc().findAll();
  }

  /// Get average glucose over period
  Future<double> getAverageGlucose(DateTime start, DateTime end) async {
    final readings = await getReadingsInRange(start, end);
    if (readings.isEmpty) return 0;
    return readings.fold<double>(0, (sum, r) => sum + r.valueMgDl) / readings.length;
  }
}

/// Glucose targets repository
class GlucoseTargetsRepository {
  final Isar _isar;

  GlucoseTargetsRepository(this._isar);

  /// Get current targets
  Future<GlucoseTargets> getTargets() async {
    final targets = await _isar.glucoseTargets.where().findFirst();
    return targets ?? GlucoseTargets();
  }

  /// Update targets
  Future<void> updateTargets(GlucoseTargets targets) async {
    await _isar.writeTxn(() async {
      await _isar.glucoseTargets.put(targets);
    });
  }
}

/// Body measurement repository
class BodyMeasurementRepository {
  final Isar _isar;

  BodyMeasurementRepository(this._isar);

  /// Get all measurements
  Future<List<BodyMeasurement>> getAll() async {
    return await _isar.bodyMeasurements.where().sortByDateDesc().findAll();
  }

  /// Get measurements in date range
  Future<List<BodyMeasurement>> getInRange(DateTime start, DateTime end) async {
    return await _isar.bodyMeasurements
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Get latest measurement
  Future<BodyMeasurement?> getLatest() async {
    return await _isar.bodyMeasurements.where().sortByDateDesc().findFirst();
  }

  /// Get measurement for a specific date
  Future<BodyMeasurement?> getForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _isar.bodyMeasurements
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findFirst();
  }

  /// Add a measurement
  Future<void> add(BodyMeasurement measurement) async {
    await _isar.writeTxn(() async {
      await _isar.bodyMeasurements.put(measurement);
    });
  }

  /// Update a measurement
  Future<void> update(BodyMeasurement measurement) async {
    await _isar.writeTxn(() async {
      await _isar.bodyMeasurements.put(measurement);
    });
  }

  /// Delete a measurement
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.bodyMeasurements.delete(id);
    });
  }

  /// Get weight history
  Future<List<BodyMeasurement>> getWeightHistory({int limit = 30}) async {
    return await _isar.bodyMeasurements
        .filter()
        .weightKgIsNotNull()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
  }

  /// Get weight statistics for a period
  Future<WeightStats?> getWeightStats(DateTime start, DateTime end) async {
    final measurements = await getInRange(start, end);
    final weightsOnly = measurements.where((m) => m.weightKg != null).toList();

    if (weightsOnly.isEmpty) return null;

    final weights = weightsOnly.map((m) => m.weightKg!).toList();
    weights.sort();

    final startWeight = weightsOnly.last.weightKg!; // Last in list = oldest
    final endWeight = weightsOnly.first.weightKg!;  // First in list = newest
    final minWeight = weights.first;
    final maxWeight = weights.last;
    final averageWeight = weights.reduce((a, b) => a + b) / weights.length;
    final change = endWeight - startWeight;
    final changePercent = startWeight > 0 ? (change / startWeight) * 100 : 0;
    final days = end.difference(start).inDays;

    return WeightStats(
      startWeight: startWeight,
      endWeight: endWeight,
      minWeight: minWeight,
      maxWeight: maxWeight,
      averageWeight: averageWeight,
      change: change,
      changePercent: changePercent.toDouble(),
      days: days,
    );
  }
}

/// User profile repository
class UserProfileRepository {
  final Isar _isar;

  UserProfileRepository(this._isar);

  /// Get user profile
  Future<UserProfile> getProfile() async {
    final profile = await _isar.userProfiles.where().findFirst();
    return profile ?? UserProfile();
  }

  /// Update user profile
  Future<void> updateProfile(UserProfile profile) async {
    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
    });
  }
}
