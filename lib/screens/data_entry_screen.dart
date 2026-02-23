import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/health_data.dart';
import '../providers/health_data_provider.dart';

class DataEntryScreen extends ConsumerStatefulWidget {
  const DataEntryScreen({super.key});

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
              const Text('Vitals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FormBuilderTextField(
                name: 'systolic',
                decoration:
                    const InputDecoration(labelText: 'Systolic BP (mmHg)'),
                keyboardType: TextInputType.number,
              ),
              FormBuilderTextField(
                name: 'diastolic',
                decoration:
                    const InputDecoration(labelText: 'Diastolic BP (mmHg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Blood Sugar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FormBuilderTextField(
                name: 'fasting_glucose',
                decoration: const InputDecoration(
                    labelText: 'Fasting Blood Sugar (mg/dL)'),
                keyboardType: TextInputType.number,
              ),
              FormBuilderTextField(
                name: 'hba1c',
                decoration: const InputDecoration(labelText: 'HbA1c (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final formData = _formKey.currentState!.value;
                    List<HealthData> entries = [];
                    final now = DateTime.now();

                    formData.forEach((key, value) {
                      if (value != null && value.toString().isNotEmpty) {
                        double? numericValue =
                            double.tryParse(value.toString());
                        if (numericValue != null) {
                          entries.add(HealthData(
                            category: _getCategoryForKey(key),
                            testName: key,
                            value: numericValue,
                            unit: _getUnitForKey(key),
                            date: now,
                          ));
                        }
                      }
                    });

                    if (entries.isNotEmpty) {
                      for (var entry in entries) {
                        await ref
                            .read(healthDataProvider.notifier)
                            .addHealthData(entry);
                      }
                      if (context.mounted) {
                        context.go('/processing');
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter at least one value.')),
                      );
                    }
                  }
                },
                child: const Text('Analyze Health Risk'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryForKey(String key) {
    if (['systolic', 'diastolic'].contains(key)) return 'vitals';
    if (['fasting_glucose', 'hba1c'].contains(key)) return 'blood_sugar';
    return 'general';
  }

  String _getUnitForKey(String key) {
    if (['systolic', 'diastolic'].contains(key)) return 'mmHg';
    if (key == 'fasting_glucose') return 'mg/dL';
    if (key == 'hba1c') return '%';
    return '';
  }
}
