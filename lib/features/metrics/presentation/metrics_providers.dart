import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/body_metrics.dart';
import '../../../data/services/database_service.dart';

/// Selected date for viewing measurements
final metricsSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Repositories
final bodyMeasurementRepositoryProvider = FutureProvider<BodyMeasurementRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return BodyMeasurementRepository(isar);
});

final userProfileRepositoryProvider = FutureProvider<UserProfileRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return UserProfileRepository(isar);
});

/// User profile
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = await ref.watch(userProfileRepositoryProvider.future);
  return await repo.getProfile();
});

/// Latest measurement
final latestMeasurementProvider = FutureProvider<BodyMeasurement?>((ref) async {
  final repo = await ref.watch(bodyMeasurementRepositoryProvider.future);
  return await repo.getLatest();
});

/// All measurements
final allMeasurementsProvider = FutureProvider<List<BodyMeasurement>>((ref) async {
  final repo = await ref.watch(bodyMeasurementRepositoryProvider.future);
  return await repo.getAll();
});

/// Weight history (last N measurements)
final weightHistoryProvider = FutureProvider.family<List<BodyMeasurement>, int>(
  (ref, limit) async {
    final repo = await ref.watch(bodyMeasurementRepositoryProvider.future);
    return await repo.getWeightHistory(limit: limit);
  },
);

/// Weight stats for a period
final weightStatsProvider = FutureProvider.family<WeightStats?, (DateTime, DateTime)>(
  (ref, dates) async {
    final repo = await ref.watch(bodyMeasurementRepositoryProvider.future);
    return await repo.getWeightStats(dates.$1, dates.$2);
  },
);

/// Measurement for a specific date
final measurementForDateProvider = FutureProvider.family<BodyMeasurement?, DateTime>(
  (ref, date) async {
    final repo = await ref.watch(bodyMeasurementRepositoryProvider.future);
    return await repo.getForDate(date);
  },
);

/// Add measurement
final addMeasurementProvider = Provider<Function(BodyMeasurement)>((ref) {
  return (BodyMeasurement measurement) async {
    final isar = await DatabaseService.instance;
    final repo = BodyMeasurementRepository(isar);
    await repo.add(measurement);
    
    ref.invalidate(latestMeasurementProvider);
    ref.invalidate(allMeasurementsProvider);
    ref.invalidate(weightHistoryProvider);
  };
});

/// Quick add weight
final quickAddWeightProvider = Provider<Function(double)>((ref) {
  return (double weightKg) async {
    final now = DateTime.now();
    final measurement = BodyMeasurement(
      uuid: const Uuid().v4(),
      date: DateTime(now.year, now.month, now.day),
      weightKg: weightKg,
    );
    
    final isar = await DatabaseService.instance;
    final repo = BodyMeasurementRepository(isar);
    await repo.add(measurement);
    
    ref.invalidate(latestMeasurementProvider);
    ref.invalidate(allMeasurementsProvider);
    ref.invalidate(weightHistoryProvider);
  };
});

/// Update user profile
final updateUserProfileProvider = Provider<Function(UserProfile)>((ref) {
  return (UserProfile profile) async {
    final isar = await DatabaseService.instance;
    final repo = UserProfileRepository(isar);
    await repo.updateProfile(profile);
    ref.invalidate(userProfileProvider);
  };
});

/// Delete measurement
final deleteMeasurementProvider = Provider<Function(int)>((ref) {
  return (int id) async {
    final isar = await DatabaseService.instance;
    final repo = BodyMeasurementRepository(isar);
    await repo.delete(id);
    
    ref.invalidate(latestMeasurementProvider);
    ref.invalidate(allMeasurementsProvider);
    ref.invalidate(weightHistoryProvider);
  };
});

/// BMI calculation provider
final bmiProvider = FutureProvider<double?>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  final measurementAsync = ref.watch(latestMeasurementProvider);

  return profileAsync.when(
    data: (profile) => measurementAsync.when(
      data: (measurement) {
        if (measurement?.weightKg == null || profile.heightMeters == null) return null;
        return measurement!.calculateBMI(profile.heightMeters!);
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});
