import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/health_data.dart';
import '../providers/health_data_provider.dart';
import '../utils/test_definitions.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialValues;
  final String rawText;

  const OcrReviewScreen(
      {super.key, required this.initialValues, required this.rawText});

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _saveDataAndNext() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState!.value;
      final now = DateTime.now();

      formValues.forEach((key, value) {
        if (value == null) return;

        // Find the test definition to get label and unit
        final testDef = getTestDefinition(key);
        if (testDef == null) return;

        final double? numericValue = double.tryParse(value.toString());
        if (numericValue != null) {
          final data = HealthData(
            category:
                'OCR Extraction', // Use a generic category or find its actual one if needed
            testName: testDef.label,
            value: numericValue,
            unit: testDef.unit,
            date: now,
          );
          ref.read(healthDataProvider.notifier).addHealthData(data);
        }
      });

      // Navigate to action choices
      context.push('/ocr-action');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate list of FormBuilderFields based on the initialValues keys
    List<Widget> formFields = [];

    // 1. Add the Raw Extracted Text Preview at the very top
    formFields.add(
      Card(
        color: Colors.blueGrey.shade50,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: ExpansionTile(
          title: const Text('View Raw OCR Output',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Tap to see exactly what the scanner read'),
          leading: const Icon(Icons.document_scanner_outlined),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                widget.rawText.isEmpty
                    ? "No text was detected."
                    : widget.rawText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    widget.initialValues.forEach((key, value) {
      final testDef = getTestDefinition(key);
      if (testDef != null) {
        formFields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FormBuilderTextField(
              name: key,
              initialValue: value.toString(),
              decoration: InputDecoration(
                labelText: testDef.label,
                suffixText: testDef.unit,
                border: const OutlineInputBorder(),
                filled: true,
              ),
              keyboardType: testDef.keyboardType,
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scanned Data'),
        backgroundColor: Colors.deepPurpleAccent.shade100,
      ),
      body: SafeArea(
        child: formFields.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 64, color: Colors.orange.shade400),
                    const SizedBox(height: 16),
                    const Text('No lab data was confidently identified.',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/ocr-action'),
                      child: const Text('Continue Anyway'),
                    )
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Please verify the extracted values. You can correct any OCR errors here before saving.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FormBuilder(
                        key: _formKey,
                        child: ListView(
                          children: formFields,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveDataAndNext,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Save Page Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
