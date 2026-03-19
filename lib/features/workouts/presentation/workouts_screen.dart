import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/synthwave_theme.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_log.dart';
import '../../../data/services/database_service.dart';
import 'workout_providers.dart';
import 'widgets/active_workout_view.dart';
import 'widgets/exercise_list_view.dart';
import 'widgets/workout_history_view.dart';

/// Main workouts screen
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: activeWorkout != null
          ? const ActiveWorkoutView()
          : const _WorkoutsHome(),
      floatingActionButton: activeWorkout == null
          ? FloatingActionButton.extended(
              onPressed: () => _showStartWorkoutDialog(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('START WORKOUT'),
            )
          : null,
    );
  }

  void _showStartWorkoutDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'Workout');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthwaveColors.surface,
        title: Text(
          'Start New Workout',
          style: SynthwaveTextStyles.displaySmall(context),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Workout Name',
            hintText: 'e.g., Push Day, Leg Day',
          ),
          style: TextStyle(color: SynthwaveColors.chrome),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).startWorkout(
                    controller.text.isEmpty ? 'Workout' : controller.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('START'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsHome extends ConsumerWidget {
  const _WorkoutsHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider);
    final recentWorkoutsAsync = ref.watch(recentWorkoutsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WORKOUTS',
              style: SynthwaveTextStyles.displayLarge(context),
            ),
            const SizedBox(height: 16),

            // Stats cards
            statsAsync.when(
              data: (stats) => _buildStatsRow(context, stats),
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Quick start templates
            Text(
              'QUICK START',
              style: SynthwaveTextStyles.labelLarge(context),
            ),
            const SizedBox(height: 12),
            _buildQuickStartButtons(context, ref),

            const SizedBox(height: 24),

            // Recent workouts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT',
                  style: SynthwaveTextStyles.labelLarge(context),
                ),
                TextButton(
                  onPressed: () => _showHistory(context),
                  child: const Text('VIEW ALL'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentWorkoutsAsync.when(
              data: (workouts) => workouts.isEmpty
                  ? _buildEmptyState(context)
                  : _buildRecentWorkoutsList(context, workouts),
              loading: () => const _LoadingCard(),
              error: (_, __) => const Text('Error loading workouts'),
            ),

            const SizedBox(height: 24),

            // Exercise library
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EXERCISE LIBRARY',
                  style: SynthwaveTextStyles.labelLarge(context),
                ),
                TextButton(
                  onPressed: () => _showExerciseLibrary(context),
                  child: const Text('BROWSE'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMuscleGroupChips(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WorkoutStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Workouts',
            value: stats.totalWorkouts.toString(),
            color: SynthwaveColors.neonPink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total Sets',
            value: stats.totalSets.toString(),
            color: SynthwaveColors.neonCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '${stats.currentStreak}d',
            color: SynthwaveColors.neonPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStartButtons(BuildContext context, WidgetRef ref) {
    final templates = [
      ('Push Day', Icons.arrow_upward, MuscleGroup.chest),
      ('Pull Day', Icons.arrow_downward, MuscleGroup.back),
      ('Leg Day', Icons.directions_walk, MuscleGroup.legs),
      ('Cardio', Icons.directions_run, MuscleGroup.fullBody),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.map((template) {
        return ActionChip(
          avatar: Icon(template.$2, color: SynthwaveColors.chrome, size: 18),
          label: Text(template.$1),
          onPressed: () {
            ref.read(activeWorkoutProvider.notifier).startWorkout(template.$1);
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SynthwaveColors.gridLine),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: SynthwaveColors.chrome.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No workouts yet',
            style: SynthwaveTextStyles.bodyMedium(context),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your first workout above!',
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutsList(BuildContext context, List<WorkoutLog> workouts) {
    return Column(
      children: workouts.take(3).map((workout) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SynthwaveColors.neonPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fitness_center, color: SynthwaveColors.neonPink),
            ),
            title: Text(workout.name),
            subtitle: Text(
              '${workout.totalSets} sets • ${workout.durationMinutes} min • ${_formatDate(workout.startTime)}',
              style: SynthwaveTextStyles.bodySmall(context),
            ),
            trailing: Text(
              '${workout.totalVolume.toInt()}',
              style: SynthwaveTextStyles.bodyLarge(context).copyWith(
                color: SynthwaveColors.neonCyan,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMuscleGroupChips(BuildContext context, WidgetRef ref) {
    final groups = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.legs,
      MuscleGroup.abs,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: groups.map((group) {
        return FilterChip(
          label: Text(_formatMuscleGroup(group)),
          selected: false,
          onSelected: (_) => _showExerciseLibrary(context, group),
        );
      }).toList(),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutHistoryView()),
    );
  }

  void _showExerciseLibrary(BuildContext context, [MuscleGroup? group]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseListView(initialMuscleGroup: group),
      ),
    );
  }

  String _formatMuscleGroup(MuscleGroup group) {
    return group.name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m[1]}',
        )
        .trim()
        .capitalize();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: SynthwaveTextStyles.displayMedium(context).copyWith(
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: SynthwaveColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

