import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/exercise.dart';
import '../../../../data/models/workout_log.dart';
import '../workout_providers.dart';

/// Active workout logging screen
class ActiveWorkoutView extends ConsumerStatefulWidget {
  const ActiveWorkoutView({super.key});

  @override
  ConsumerState<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends ConsumerState<ActiveWorkoutView> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) return const SizedBox.shrink();

    final elapsedMinutes = workout.durationMinutes;
    final totalVolume = workout.totalVolume.toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name.toUpperCase()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => _showFinishDialog(context, ref),
            child: const Text('FINISH'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout header stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SynthwaveColors.surface,
              border: Border(
                bottom: BorderSide(color: SynthwaveColors.gridLine),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('TIME', '${elapsedMinutes}m', SynthwaveColors.neonPink),
                _buildStat('VOLUME', '$totalVolume', SynthwaveColors.neonCyan),
                _buildStat('EXERCISES', '${workout.exercises.length}', SynthwaveColors.neonPurple),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: workout.exercises.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, index) {
                      return _ExerciseCard(
                        exercise: workout.exercises[index],
                        exerciseIndex: index,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ADD EXERCISE'),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: SynthwaveColors.chrome.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first exercise',
            style: SynthwaveTextStyles.bodyLarge(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to get started',
            style: SynthwaveTextStyles.bodySmall(context),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to exercise picker
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthwaveColors.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _ExercisePickerSheet(
            scrollController: scrollController,
            onExerciseSelected: (exercise) {
              ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
              Navigator.pop(context);
              // Scroll to bottom after adding
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthwaveColors.surface,
        title: Text('Cancel Workout?', style: SynthwaveTextStyles.displaySmall(context)),
        content: Text(
          'All progress will be lost.',
          style: SynthwaveTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KEEP GOING'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SynthwaveColors.error,
            ),
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
              Navigator.pop(context);
            },
            child: const Text('CANCEL WORKOUT'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthwaveColors.surface,
        title: Text('Finish Workout?', style: SynthwaveTextStyles.displaySmall(context)),
        content: Text(
          'Save this workout to your history.',
          style: SynthwaveTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE'),
          ),
          ElevatedButton(
            onPressed: () async {
              ref.read(activeWorkoutProvider.notifier).completeWorkout();
              await ref.read(activeWorkoutProvider.notifier).saveWorkout();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout saved!')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final LoggedExercise exercise;
  final int exerciseIndex;

  const _ExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.exerciseName,
                        style: SynthwaveTextStyles.bodyLarge(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMuscleGroup(widget.exercise.muscleGroup),
                        style: SynthwaveTextStyles.bodySmall(context).copyWith(
                          color: SynthwaveColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showExerciseOptions(context),
                ),
              ],
            ),

            const Divider(height: 24),

            // Sets header
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('SET', style: SynthwaveTextStyles.labelMedium(context)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('LBS', style: SynthwaveTextStyles.labelMedium(context)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('REPS', style: SynthwaveTextStyles.labelMedium(context)),
                ),
                const SizedBox(width: 40),
              ],
            ),

            const SizedBox(height: 8),

            // Sets list
            ...widget.exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(
                set: set,
                exerciseIndex: widget.exerciseIndex,
                setIndex: index,
              );
            }),

            const SizedBox(height: 12),

            // Add set button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD SET'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSet() {
    final newSet = WorkoutSet()
      ..setNumber = widget.exercise.sets.length + 1;
    
    // Copy weight from previous set if available
    if (widget.exercise.sets.isNotEmpty) {
      final lastSet = widget.exercise.sets.last;
      newSet.weight = lastSet.weight;
    }

    ref.read(activeWorkoutProvider.notifier).addSet(widget.exerciseIndex, newSet);
  }

  void _showExerciseOptions(BuildContext context) {
    // TODO: Implement exercise options (reorder, delete, rest timer settings)
  }

  String _formatMuscleGroup(MuscleGroup group) {
    return group.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .capitalize();
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final WorkoutSet set;
  final int exerciseIndex;
  final int setIndex;

  const _SetRow({
    required this.set,
    required this.exerciseIndex,
    required this.setIndex,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if set data changed externally
    if (oldWidget.set.weight != widget.set.weight) {
      _weightController.text = widget.set.weight?.toString() ?? '';
    }
    if (oldWidget.set.reps != widget.set.reps) {
      _repsController.text = widget.set.reps?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Set number
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.set.isComplete
                    ? SynthwaveColors.neonCyan.withOpacity(0.2)
                    : SynthwaveColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.set.setNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.set.isComplete
                      ? SynthwaveColors.neonCyan
                      : SynthwaveColors.chrome,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Weight input
          Expanded(
            flex: 3,
            child: TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) => _updateSet(),
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            flex: 3,
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) => _updateSet(),
            ),
          ),
          const SizedBox(width: 8),

          // Complete checkbox
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                widget.set.isComplete ? Icons.check_circle : Icons.check_circle_outline,
                color: widget.set.isComplete
                    ? SynthwaveColors.neonCyan
                    : SynthwaveColors.chrome.withOpacity(0.5),
              ),
              onPressed: _toggleComplete,
            ),
          ),
        ],
      ),
    );
  }

  void _updateSet() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    final updatedSet = WorkoutSet()
      ..setNumber = widget.set.setNumber
      ..weight = weight
      ..reps = reps
      ..isComplete = widget.set.isComplete;

    ref.read(activeWorkoutProvider.notifier).updateSet(
          widget.exerciseIndex,
          widget.setIndex,
          updatedSet,
        );
  }

  void _toggleComplete() {
    final updatedSet = WorkoutSet()
      ..setNumber = widget.set.setNumber
      ..weight = widget.set.weight
      ..reps = widget.set.reps
      ..isComplete = !widget.set.isComplete;

    ref.read(activeWorkoutProvider.notifier).updateSet(
          widget.exerciseIndex,
          widget.setIndex,
          updatedSet,
        );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }
}

// Placeholder for exercise picker
class _ExercisePickerSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final Function(dynamic) onExerciseSelected;

  const _ExercisePickerSheet({
    required this.scrollController,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: SynthwaveColors.chrome.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'SELECT EXERCISE',
            style: SynthwaveTextStyles.labelLarge(context),
          ),
        ),

        // Exercise list
        Expanded(
          child: exercisesAsync.when(
            data: (exercises) => ListView.builder(
              controller: scrollController,
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${_formatMuscleGroup(exercise.primaryMuscleGroup)} • ${_formatEquipment(exercise.equipment)}',
                    style: SynthwaveTextStyles.bodySmall(context),
                  ),
                  onTap: () => onExerciseSelected(exercise),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading exercises')),
          ),
        ),
      ],
    );
  }

  String _formatMuscleGroup(MuscleGroup group) {
    return group.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .capitalize();
  }

  String _formatEquipment(Equipment equipment) {
    if (equipment == Equipment.none) return 'Bodyweight';
    return equipment.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .capitalize();
  }
}

