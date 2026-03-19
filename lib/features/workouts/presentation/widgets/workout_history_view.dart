import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/workout_log.dart';
import '../workout_providers.dart';

/// Workout history list
class WorkoutHistoryView extends ConsumerWidget {
  const WorkoutHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(recentWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORKOUT HISTORY'),
      ),
      body: workoutsAsync.when(
        data: (workouts) => workouts.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _WorkoutCard(workout: workout);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading history')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history yet',
            style: SynthwaveTextStyles.bodyLarge(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first workout to see it here!',
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutLog workout;

  const _WorkoutCard({required this.workout});

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: SynthwaveTextStyles.bodyLarge(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(workout.startTime),
                        style: SynthwaveTextStyles.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SynthwaveColors.neonPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${workout.totalVolume.toInt()}',
                    style: TextStyle(
                      color: SynthwaveColors.neonPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(
                  icon: Icons.timer,
                  value: '${workout.durationMinutes}m',
                  color: SynthwaveColors.neonCyan,
                ),
                const SizedBox(width: 16),
                _buildStat(
                  icon: Icons.fitness_center,
                  value: '${workout.totalSets} sets',
                  color: SynthwaveColors.neonPurple,
                ),
                const SizedBox(width: 16),
                _buildStat(
                  icon: Icons.sports_gymnastics,
                  value: '${workout.exercises.length} ex',
                  color: SynthwaveColors.neonYellow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: SynthwaveColors.chrome.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today at ${_formatTime(date)}';
    if (diff.inDays == 1) return 'Yesterday at ${_formatTime(date)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}
