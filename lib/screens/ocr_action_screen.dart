import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OcrActionScreen extends StatelessWidget {
  const OcrActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Saved'),
        backgroundColor: Colors.deepPurpleAccent.shade100,
        automaticallyImplyLeading: false, // Prevent going back to Review
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Report Page Saved Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to do next?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Option 1: Capture Next Page
              ElevatedButton.icon(
                onPressed: () {
                  // Pop to scanner so we don't build a huge navigation history stack
                  context.pushReplacement('/ocr-scanner');
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Capture Next Page'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple.shade50,
                  foregroundColor: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Option 2: Add Manual Data
              ElevatedButton.icon(
                onPressed: () {
                  // Go to regular data category flow
                  context.push('/data-category');
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Add Missing Data Manually'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Option 3: Finish and Analyze
              ElevatedButton.icon(
                onPressed: () {
                  // Finish the flow and jump to evaluation
                  context.push('/processing');
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Finish & Analyze Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
