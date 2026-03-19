import 'package:flutter/material.dart';
import '../../../../core/theme/synthwave_theme.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/glucose.dart';

/// Dialog for adding a glucose reading
class GlucoseAddDialog extends StatefulWidget {
  final GlucoseContext defaultContext;
  final Function(double, GlucoseContext, String?) onAdd;

  const GlucoseAddDialog({
    super.key,
    required this.defaultContext,
    required this.onAdd,
  });

  @override
  State<GlucoseAddDialog> createState() => _GlucoseAddDialogState();
}

class _GlucoseAddDialogState extends State<GlucoseAddDialog> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  late GlucoseContext _selectedContext;
  GlucoseUnit _unit = GlucoseUnit.mgDl;

  @override
  void initState() {
    super.initState();
    _selectedContext = widget.defaultContext;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SynthwaveColors.surface,
      title: Text('Log Glucose', style: SynthwaveTextStyles.displaySmall(context)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit selector
            Row(
              children: [
                ChoiceChip(
                  label: const Text('mg/dL'),
                  selected: _unit == GlucoseUnit.mgDl,
                  onSelected: (selected) {
                    if (selected) setState(() => _unit = GlucoseUnit.mgDl);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('mmol/L'),
                  selected: _unit == GlucoseUnit.mmolL,
                  onSelected: (selected) {
                    if (selected) setState(() => _unit = GlucoseUnit.mmolL);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Value input
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Glucose Value',
                hintText: _unit == GlucoseUnit.mgDl ? 'e.g., 100' : 'e.g., 5.5',
                suffixText: _unit == GlucoseUnit.mgDl ? 'mg/dL' : 'mmol/L',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Context selector
            Text('Context', style: SynthwaveTextStyles.labelMedium(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GlucoseContext.values.map((ctx) {
                return ChoiceChip(
                  label: Text(_formatContext(ctx)),
                  selected: _selectedContext == ctx,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedContext = ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., after breakfast',
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
          onPressed: _saveReading,
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  void _saveReading() {
    final inputValue = double.tryParse(_valueController.text);
    if (inputValue == null || inputValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid glucose value')),
      );
      return;
    }

    // Convert to mg/dL if needed
    double valueMgDl;
    if (_unit == GlucoseUnit.mmolL) {
      valueMgDl = inputValue * 18.0; // mmol/L to mg/dL
    } else {
      valueMgDl = inputValue;
    }

    widget.onAdd(valueMgDl, _selectedContext, _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
    Navigator.pop(context);
  }

  String _formatContext(GlucoseContext ctx) {
    switch (ctx) {
      case GlucoseContext.fasting:
        return 'Fasting';
      case GlucoseContext.preMeal:
        return 'Pre-Meal';
      case GlucoseContext.postMeal:
        return 'Post-Meal';
      case GlucoseContext.bedtime:
        return 'Bedtime';
      case GlucoseContext.general:
        return 'General';
    }
  }
}
