import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/exercise.dart';
import '../workout_providers.dart';

/// Exercise library browser
class ExerciseListView extends ConsumerWidget {
  final MuscleGroup? initialMuscleGroup;

  const ExerciseListView({
    super.key,
    this.initialMuscleGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.watch(selectedMuscleGroupProvider);
    final exercisesAsync = selectedGroup != null
        ? ref.watch(exercisesByMuscleGroupProvider(selectedGroup))
        : ref.watch(allExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXERCISE LIBRARY'),
      ),
      body: Column(
        children: [
          // Muscle group filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedGroup == null,
                  onSelected: (_) => ref.read(selectedMuscleGroupProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                ...MuscleGroup.values.map((group) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_formatMuscleGroup(group)),
                    selected: selectedGroup == group,
                    onSelected: (_) => ref.read(selectedMuscleGroupProvider.notifier).state = group,
                  ),
                )),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${_formatMuscleGroup(exercise.primaryMuscleGroup)} • ${_formatEquipment(exercise.equipment)}',
                        style: SynthwaveTextStyles.bodySmall(context),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: SynthwaveColors.chrome.withOpacity(0.5),
                      ),
                      onTap: () => _showExerciseDetails(context, exercise),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading exercises')),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
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
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SynthwaveColors.chrome.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  exercise.name.toUpperCase(),
                  style: SynthwaveTextStyles.displaySmall(context),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatMuscleGroup(exercise.primaryMuscleGroup)} • ${_formatEquipment(exercise.equipment)}',
                  style: TextStyle(color: SynthwaveColors.neonCyan),
                ),
                const SizedBox(height: 24),

                if (exercise.instructions.isNotEmpty) ...[
                  Text(
                    'INSTRUCTIONS',
                    style: SynthwaveTextStyles.labelLarge(context),
                  ),
                  const SizedBox(height: 12),
                  ...exercise.instructions.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: TextStyle(color: SynthwaveColors.neonPink),
                        ),
                        Expanded(
                          child: Text(entry.value),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                ],

                if (exercise.tips.isNotEmpty) ...[
                  Text(
                    'TIPS',
                    style: SynthwaveTextStyles.labelLarge(context),
                  ),
                  const SizedBox(height: 12),
                  ...exercise.tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 16,
                          color: SynthwaveColors.neonYellow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
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

