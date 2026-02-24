import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/health_data.dart';
import '../providers/health_data_provider.dart';
import '../utils/test_definitions.dart';

class DataEntryScreen extends ConsumerStatefulWidget {
  final List<String> selectedCategories;
  final Map<String, dynamic>? initialValues;

  const DataEntryScreen({
    super.key,
    required this.selectedCategories,
    this.initialValues,
  });

  @override
  ConsumerState<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends ConsumerState<DataEntryScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Lab Data & Vitals')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildDynamicFields(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Analyze Health Risk'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    List<Widget> widgets = [];

    if (widget.selectedCategories.isEmpty) {
      return [const Text('No categories selected.')];
    }

    for (var category in widget.selectedCategories) {
      final tests = medicalTestCategories[category];
      if (tests == null || tests.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            category,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
      );

      for (var test in tests) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FormBuilderTextField(
              name: test.key,
              initialValue: widget.initialValues?[test.key]?.toString(),
              decoration: InputDecoration(
                labelText: test.label,
                suffixText: test.unit.isNotEmpty ? test.unit : null,
                border: const OutlineInputBorder(),
              ),
              keyboardType: test.keyboardType,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      List<HealthData> entries = [];
      final now = DateTime.now();

      formData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          double? numericValue = double.tryParse(value.toString());
          if (numericValue != null) {
            // Look up the definition for this key to get its real Category and Unit
            final def = getTestDefinition(key);
            String actualCategory = 'General';

            // Find which category this test belongs to in the master dictionary
            for (var entry in medicalTestCategories.entries) {
              if (entry.value.any((t) => t.key == key)) {
                actualCategory = entry.key;
                break;
              }
            }

            entries.add(HealthData(
              category: actualCategory,
              testName: def?.label ?? key,
              value: numericValue,
              unit: def?.unit ?? '',
              date: now,
            ));
          }
        }
      });

      if (entries.isNotEmpty) {
        for (var entry in entries) {
          await ref.read(healthDataProvider.notifier).addHealthData(entry);
        }
        if (context.mounted) {
          context.go('/processing');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one value.')),
        );
      }
    }
  }
}
