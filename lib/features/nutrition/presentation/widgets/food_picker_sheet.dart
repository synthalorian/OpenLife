import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/food.dart';
import '../nutrition_providers.dart';

/// Food picker sheet for adding foods to a meal
class FoodPickerSheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final ScrollController scrollController;
  final VoidCallback onComplete;

  const FoodPickerSheet({
    super.key,
    required this.mealType,
    required this.scrollController,
    required this.onComplete,
  });

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activeMeal = ref.watch(activeMealProvider);
    final foodsAsync = _searchQuery.isEmpty
        ? ref.watch(favoriteFoodsProvider)
        : ref.watch(foodSearchProvider(_searchQuery));

    return Column(
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SynthwaveColors.chrome.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'ADD FOOD TO ${widget.mealType.name.toUpperCase()}',
                style: SynthwaveTextStyles.labelLarge(context),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search foods...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),

        // Selected foods summary
        if (activeMeal != null && activeMeal.foods.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: SynthwaveColors.neonCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SynthwaveColors.neonCyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${activeMeal.foods.length} items selected',
                  style: TextStyle(color: SynthwaveColors.neonCyan),
                ),
                Text(
                  '${activeMeal.totalCalories.toInt()} kcal',
                  style: TextStyle(
                    color: SynthwaveColors.neonCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Food list
        Expanded(
          child: foodsAsync.when(
            data: (foods) => foods.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      return _FoodListTile(
                        food: foods[index],
                        onTap: () => _showQuantityDialog(context, foods[index]),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading foods')),
          ),
        ),

        // Bottom actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SynthwaveColors.surface,
            border: Border(top: BorderSide(color: SynthwaveColors.gridLine)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(activeMealProvider.notifier).cancelMeal();
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: activeMeal?.foods.isNotEmpty == true
                      ? () async {
                          await ref.read(activeMealProvider.notifier).saveMeal();
                          widget.onComplete();
                        }
                      : null,
                  child: const Text('SAVE MEAL'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: SynthwaveColors.chrome.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty ? 'No favorite foods' : 'No foods found',
            style: TextStyle(color: SynthwaveColors.chrome.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Food food) {
    final quantityController = TextEditingController(text: '1');
    ServingUnit selectedUnit = food.servingUnit;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthwaveColors.surface,
        title: Text(food.name, style: SynthwaveTextStyles.displaySmall(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Per serving: ${food.calories.toInt()} kcal • P:${food.protein.toInt()}g C:${food.carbs.toInt()}g F:${food.fat.toInt()}g',
              style: SynthwaveTextStyles.bodySmall(context),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ServingUnit>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: ServingUnit.values.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.name.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) selectedUnit = value;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 1;
              ref.read(activeMealProvider.notifier).addFood(food, quantity, selectedUnit);
              Navigator.pop(context);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}

class _FoodListTile extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const _FoodListTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(food.name),
      subtitle: Text(
        '${food.calories.toInt()} kcal per ${_food.servingSize.toInt()}${_formatUnit(food.servingUnit)}',
        style: SynthwaveTextStyles.bodySmall(context),
      ),
      trailing: Icon(
        Icons.add_circle_outline,
        color: SynthwaveColors.neonCyan,
      ),
      onTap: onTap,
    );
  }

  Food get _food => food;

  String _formatUnit(ServingUnit unit) {
    switch (unit) {
      case ServingUnit.gram:
        return 'g';
      case ServingUnit.milliliter:
        return 'ml';
      case ServingUnit.piece:
        return 'pc';
      default:
        return unit.name;
    }
  }
}
