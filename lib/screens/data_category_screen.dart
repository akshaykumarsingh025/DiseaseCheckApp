import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DataCategoryScreen extends StatefulWidget {
  const DataCategoryScreen({super.key});

  @override
  State<DataCategoryScreen> createState() => _DataCategoryScreenState();
}

class _DataCategoryScreenState extends State<DataCategoryScreen> {
  final List<String> categories = [
    'Vitals',
    'Blood Sugar / Diabetes Panel',
    'Lipid Panel (Cholesterol)',
    'Complete Blood Count (CBC)',
    'Liver Function Tests (LFT)',
    'Kidney Function Tests (KFT)',
  ];
  final Set<String> _selected = {};

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
                      // Pass selected categories to data entry
                      context.push('/data-entry', extra: _selected.toList());
                    },
              child: const Text('Proceed to Entry'),
            ),
          )
        ],
      ),
    );
  }
}
