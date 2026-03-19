import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../data/models/body_metrics.dart';
import '../metrics_providers.dart';

/// Dialog for adding body measurements
class AddMeasurementDialog extends StatefulWidget {
  final bool weightOnly;
  final Function(BodyMeasurement) onAdd;

  const AddMeasurementDialog({
    super.key,
    this.weightOnly = false,
    required this.onAdd,
  });

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _leftArmController = TextEditingController();
  final _rightArmController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightThighController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  WeightUnit _weightUnit = WeightUnit.kg;
  LengthUnit _lengthUnit = LengthUnit.cm;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SynthwaveColors.surface,
      title: Text(
        widget.weightOnly ? 'Log Weight' : 'Add Measurements',
        style: SynthwaveTextStyles.displaySmall(context),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: SynthwaveColors.neonCyan),
              title: Text(_formatDate(_selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Weight input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: _weightUnit == WeightUnit.kg ? 'kg' : 'lbs',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('kg'),
                  selected: _weightUnit == WeightUnit.kg,
                  onSelected: (selected) {
                    if (selected) setState(() => _weightUnit = WeightUnit.kg);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('lbs'),
                  selected: _weightUnit == WeightUnit.lbs,
                  onSelected: (selected) {
                    if (selected) setState(() => _weightUnit = WeightUnit.lbs);
                  },
                ),
              ],
            ),

            if (!widget.weightOnly) ...[
              const SizedBox(height: 16),

              // Body fat
              TextField(
                controller: _bodyFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Body Fat %',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),

              // Measurements section
              Text('BODY MEASUREMENTS', style: SynthwaveTextStyles.labelMedium(context)),
              const SizedBox(height: 12),

              // Unit selector
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('cm'),
                    selected: _lengthUnit == LengthUnit.cm,
                    onSelected: (selected) {
                      if (selected) setState(() => _lengthUnit = LengthUnit.cm);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('inches'),
                    selected: _lengthUnit == LengthUnit.inches,
                    onSelected: (selected) {
                      if (selected) setState(() => _lengthUnit = LengthUnit.inches);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Measurement grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3,
                children: [
                  _buildMeasurementField(_chestController, 'Chest'),
                  _buildMeasurementField(_waistController, 'Waist'),
                  _buildMeasurementField(_hipsController, 'Hips'),
                  _buildMeasurementField(_leftArmController, 'Left Arm'),
                  _buildMeasurementField(_rightArmController, 'Right Arm'),
                  _buildMeasurementField(_leftThighController, 'Left Thigh'),
                  _buildMeasurementField(_rightThighController, 'Right Thigh'),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _saveMeasurement,
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Widget _buildMeasurementField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: _lengthUnit == LengthUnit.cm ? 'cm' : 'in',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _saveMeasurement() {
    final weightValue = double.tryParse(_weightController.text);
    final bodyFatValue = double.tryParse(_bodyFatController.text);

    // Convert to stored units (kg and cm)
    double? weightKg;
    if (weightValue != null && weightValue > 0) {
      weightKg = _weightUnit == WeightUnit.lbs ? weightValue / 2.20462 : weightValue;
    }

    double? toCm(String? value) {
      final v = double.tryParse(value ?? '');
      if (v == null || v <= 0) return null;
      return _lengthUnit == LengthUnit.inches ? v * 2.54 : v;
    }

    final measurement = BodyMeasurement(
      uuid: const Uuid().v4(),
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      weightKg: weightKg,
      bodyFatPercent: bodyFatValue != null && bodyFatValue > 0 ? bodyFatValue : null,
      chestCm: toCm(_chestController.text),
      waistCm: toCm(_waistController.text),
      hipsCm: toCm(_hipsController.text),
      leftArmCm: toCm(_leftArmController.text),
      rightArmCm: toCm(_rightArmController.text),
      leftThighCm: toCm(_leftThighController.text),
      rightThighCm: toCm(_rightThighController.text),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    widget.onAdd(measurement);
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${date.month}/${date.day}/${date.year}';
  }
}
