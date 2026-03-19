import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/models/workout_log.dart';
import '../../../../data/services/database_service.dart';

final databaseProvider = FutureProvider<void>((ref) async {
  await DatabaseService.instance;
});

final exerciseRepositoryProvider = FutureProvider<ExerciseRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return ExerciseRepository(isar);
});

final workoutLogRepositoryProvider = FutureProvider<WorkoutLogRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return WorkoutLogRepository(isar);
});

/// All exercises
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = await ref.watch(exerciseRepositoryProvider.future);
  return await repo.getAll();
});

/// Exercises by muscle group
final exercisesByMuscleGroupProvider = FutureProvider.family<List<Exercise>, MuscleGroup>(
  (ref, group) async {
    final repo = await ref.watch(exerciseRepositoryProvider.future);
    return await repo.getByMuscleGroup(group);
  },
);

/// Search exercises
final exerciseSearchProvider = FutureProvider.family<List<Exercise>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];
    final repo = await ref.watch(exerciseRepositoryProvider.future);
    return await repo.search(query);
  },
);

/// Recent workouts
final recentWorkoutsProvider = FutureProvider<List<WorkoutLog>>((ref) async {
  final repo = await ref.watch(workoutLogRepositoryProvider.future);
  return await repo.getRecent(10);
});

/// Workout stats
final workoutStatsProvider = FutureProvider<WorkoutStats>((ref) async {
  final repo = await ref.watch(workoutLogRepositoryProvider.future);
  return await repo.getStats();
});

/// Active workout (in progress)
final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, WorkoutLog?>(
  (ref) => ActiveWorkoutNotifier(),
);

class ActiveWorkoutNotifier extends StateNotifier<WorkoutLog?> {
  ActiveWorkoutNotifier() : super(null);

  void startWorkout(String name) {
    state = WorkoutLog.inProgress(
      uuid: const Uuid().v4(),
      name: name,
    );
  }

  void addExercise(Exercise exercise) {
    if (state == null) return;

    final loggedExercise = LoggedExercise()
      ..exerciseUuid = exercise.uuid
      ..exerciseName = exercise.name
      ..muscleGroup = exercise.primaryMuscleGroup
      ..orderIndex = state!.exercises.length
      ..sets = [WorkoutSet()..setNumber = 1];

    state = WorkoutLog(
      uuid: state!.uuid,
      name: state!.name,
      startTime: state!.startTime,
      endTime: state!.endTime,
      exercises: [...state!.exercises, loggedExercise],
      notes: state!.notes,
      rating: state!.rating,
      energyLevel: state!.energyLevel,
    );
  }

  void addSet(int exerciseIndex, WorkoutSet set) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;

    final exercises = [...state!.exercises];
    final exercise = exercises[exerciseIndex];
    final newSet = WorkoutSet()
      ..setNumber = exercise.sets.length + 1;

    exercise.sets = [...exercise.sets, newSet];

    state = WorkoutLog(
      uuid: state!.uuid,
      name: state!.name,
      startTime: state!.startTime,
      endTime: state!.endTime,
      exercises: exercises,
      notes: state!.notes,
      rating: state!.rating,
      energyLevel: state!.energyLevel,
    );
  }

  void updateSet(int exerciseIndex, int setIndex, WorkoutSet updatedSet) {
    if (state == null || 
        exerciseIndex >= state!.exercises.length ||
        setIndex >= state!.exercises[exerciseIndex].sets.length) return;

    final exercises = [...state!.exercises];
    exercises[exerciseIndex].sets[setIndex] = updatedSet;

    state = WorkoutLog(
      uuid: state!.uuid,
      name: state!.name,
      startTime: state!.startTime,
      endTime: state!.endTime,
      exercises: exercises,
      notes: state!.notes,
      rating: state!.rating,
      energyLevel: state!.energyLevel,
    );
  }

  void completeWorkout() {
    if (state == null) return;
    state!.complete();
    state = WorkoutLog(
      uuid: state!.uuid,
      name: state!.name,
      startTime: state!.startTime,
      endTime: state!.endTime,
      exercises: state!.exercises,
      notes: state!.notes,
      rating: state!.rating,
      energyLevel: state!.energyLevel,
    );
  }

  void cancelWorkout() {
    state = null;
  }

  Future<void> saveWorkout() async {
    if (state == null) return;
    
    final isar = await DatabaseService.instance;
    final repo = WorkoutLogRepository(isar);
    await repo.create(state!);
    state = null;
  }
}

/// Selected muscle group filter
final selectedMuscleGroupProvider = StateProvider<MuscleGroup?>((ref) => null);
