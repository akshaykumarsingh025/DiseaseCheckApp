import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import '../providers/health_data_provider.dart';
import '../providers/session_provider.dart';
import '../utils/test_definitions.dart';
import '../engine/critical_value_checker.dart';

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
  bool _combineWithHistory = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString('draft_data_entry');
    if (draftJson != null && mounted) {
      final draft = Map<String, dynamic>.from(
        (jsonDecode(draftJson) as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
      );
      _formKey.currentState?.patchValue(draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restored unsaved draft'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _saveDraft() async {
    _formKey.currentState?.save();
    final data = _formKey.currentState?.value;
    if (data != null && data.isNotEmpty) {
      final cleaned = data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_data_entry', jsonEncode(cleaned));
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_data_entry');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Lab Data & Vitals')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          onChanged: () => _saveDraft(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildDynamicFields(),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text('Combine with Past Data',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Include all your previous lab History in this new Report for a complete assessment.',
                      style: TextStyle(fontSize: 12)),
                  value: _combineWithHistory,
                  onChanged: (val) => setState(() => _combineWithHistory = val),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analyze Health Risk'),
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
      setState(() => _isSubmitting = true);
      try {
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
          // Check for critical values before proceeding
          Map<String, double> valueMap = {
            for (var e in entries) e.testName: e.value,
          };
          final keyMap = <String, double>{};
          for (var entry in valueMap.entries) {
            final key = labelToKey[entry.key] ?? entry.key;
            keyMap[key] = entry.value;
          }
          final criticalAlerts = CriticalValueChecker.checkValues(keyMap);
          if (criticalAlerts.isNotEmpty && context.mounted) {
            CriticalValueChecker.showCriticalAlert(context, criticalAlerts);
          }

          // 1. Always save to physical storage / global history (for Trends & Women's Hub)
          for (var entry in entries) {
            await ref.read(healthDataProvider.notifier).addHealthData(entry);
          }

          // 2. Prepare the Temporary Session Provider for THIS specific report
          final session = ref.read(currentSessionProvider.notifier);
          session.clearSession();

          if (!mounted) return;
          if (_combineWithHistory) {
            // Add all historical data PLUS the newly added data
            session.addMultipleData(ref.read(healthDataProvider));
          } else {
            // ONLY add the new data we just entered
            session.addMultipleData(entries);
          }

          if (context.mounted) {
            await _clearDraft();
            context.go('/processing');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter at least one value.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }
}
