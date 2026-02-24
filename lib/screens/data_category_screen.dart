import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/test_definitions.dart';

class DataCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? initialValues;

  const DataCategoryScreen({super.key, this.initialValues});

  @override
  State<DataCategoryScreen> createState() => _DataCategoryScreenState();
}

class _DataCategoryScreenState extends State<DataCategoryScreen> {
  final List<String> categories = medicalTestCategories.keys.toList();
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null && widget.initialValues!.isNotEmpty) {
      _selected.add('Imaging Findings (OCR)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Data to Enter')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selected.contains(cat);
                return CheckboxListTile(
                  title: Text(cat),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(cat);
                      } else {
                        _selected.remove(cat);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      // Pass selected categories and initial values to data entry
                      context.push('/data-entry', extra: {
                        'categories': _selected.toList(),
                        'initialValues': widget.initialValues,
                      });
                    },
              child: const Text('Proceed to Entry'),
            ),
          )
        ],
      ),
    );
  }
}
