import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/glucose.dart';
import '../../../data/services/database_service.dart';

/// Selected date for glucose viewing
final glucoseSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Glucose repositories
final glucoseRepositoryProvider = FutureProvider<GlucoseRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return GlucoseRepository(isar);
});

final glucoseTargetsRepositoryProvider = FutureProvider<GlucoseTargetsRepository>((ref) async {
  final isar = await DatabaseService.instance;
  return GlucoseTargetsRepository(isar);
});

/// Daily glucose summary
final dailyGlucoseSummaryProvider = FutureProvider.family<DailyGlucoseSummary, DateTime>(
  (ref, date) async {
    final repo = await ref.watch(glucoseRepositoryProvider.future);
    return await repo.getDailySummary(date);
  },
);

/// Recent glucose readings
final recentGlucoseReadingsProvider = FutureProvider<List<GlucoseReading>>((ref) async {
  final repo = await ref.watch(glucoseRepositoryProvider.future);
  return await repo.getRecentReadings(20);
});

/// Glucose targets
final glucoseTargetsProvider = FutureProvider<GlucoseTargets>((ref) async {
  final repo = await ref.watch(glucoseTargetsRepositoryProvider.future);
  return await repo.getTargets();
});

/// Add glucose reading
final addGlucoseReadingProvider = Provider<Function(GlucoseReading)>((ref) {
  return (GlucoseReading reading) async {
    final isar = await DatabaseService.instance;
    final repo = GlucoseRepository(isar);
    await repo.addReading(reading);
    // Invalidate relevant providers
    ref.invalidate(dailyGlucoseSummaryProvider);
    ref.invalidate(recentGlucoseReadingsProvider);
  };
});

/// Quick add glucose reading
final quickAddGlucoseProvider = Provider<Function(double, GlucoseContext, String?)>((ref) {
  return (double valueMgDl, GlucoseContext context, String? notes) async {
    final reading = GlucoseReading(
      uuid: const Uuid().v4(),
      timestamp: DateTime.now(),
      valueMgDl: valueMgDl,
      context: context,
      notes: notes,
    );
    
    final isar = await DatabaseService.instance;
    final repo = GlucoseRepository(isar);
    await repo.addReading(reading);
    
    ref.invalidate(dailyGlucoseSummaryProvider);
    ref.invalidate(recentGlucoseReadingsProvider);
  };
});

/// Delete glucose reading
final deleteGlucoseReadingProvider = Provider<Function(int)>((ref) {
  return (int id) async {
    final isar = await DatabaseService.instance;
    final repo = GlucoseRepository(isar);
    await repo.deleteReading(id);
    
    ref.invalidate(dailyGlucoseSummaryProvider);
    ref.invalidate(recentGlucoseReadingsProvider);
  };
});

/// Update glucose targets
final updateGlucoseTargetsProvider = Provider<Function(GlucoseTargets)>((ref) {
  return (GlucoseTargets targets) async {
    final isar = await DatabaseService.instance;
    final repo = GlucoseTargetsRepository(isar);
    await repo.updateTargets(targets);
    ref.invalidate(glucoseTargetsProvider);
  };
});

/// Glucose stats for a period
final glucoseStatsProvider = FutureProvider.family<Map<String, dynamic>, (DateTime, DateTime)>(
  (ref, dates) async {
    final repo = await ref.watch(glucoseRepositoryProvider.future);
    final readings = await repo.getReadingsInRange(dates.$1, dates.$2);
    
    if (readings.isEmpty) {
      return {
        'count': 0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'timeInRange': 0.0,
      };
    }
    
    final summary = DailyGlucoseSummary(date: dates.$1, readings: readings);
    
    return {
      'count': readings.length,
      'average': summary.average,
      'min': summary.min,
      'max': summary.max,
      'timeInRange': summary.timeInRange,
      'estimatedA1C': summary.estimatedA1C,
      'classificationCounts': summary.classificationCounts,
    };
  },
);
