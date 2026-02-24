import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../engine/ocr_parser.dart';
import '../models/health_data.dart';
import '../providers/health_data_provider.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  File? _image;
  String _extractedText = '';
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _extractedText = '';
        });
        _processImage(_image!);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
        _isProcessing = false;
      });

      // Temporary logging to console for debugging pure text extraction
      print('--- ML KIT OCR EXTRACTED TEXT ---');
      print(_extractedText);
      print('---------------------------------');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error processing image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medical Report'),
        backgroundColor: Colors.deepPurpleAccent.shade100,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isProcessing) const LinearProgressIndicator(),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!, fit: BoxFit.contain),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Select an image to scan',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ),

            // Extracted Text Preview area (for debugging and review)
            if (_extractedText.isNotEmpty)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black26
                        : Colors.white,
                    border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Extracted Text (Raw)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _extractedText,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.greenAccent
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          // 1. Analyze the text
                          final flags = OcrParser.analyze(_extractedText);

                          // 2. Map results to HealthData objects
                          final now = DateTime.now();
                          final parsedData = flags.entries.map((entry) {
                            String testName = '';
                            if (entry.key == 'fatty_liver_flag')
                              testName = 'Fatty Liver Found (0=No, 1=Yes)';
                            if (entry.key == 'gallstone_flag')
                              testName = 'Gallstones Found (0=No, 1=Yes)';
                            if (entry.key == 'kidney_stone_flag')
                              testName = 'Kidney Stones Found (0=No, 1=Yes)';
                            if (entry.key == 'pneumonia_flag')
                              testName =
                                  'Lung Consolidation/Pneumonia (0=No, 1=Yes)';

                            return HealthData(
                              category: 'Imaging Findings (OCR)',
                              testName: testName,
                              value: entry.value,
                              unit: 'Flag',
                              date: now,
                            );
                          }).toList();

                          // 3. Save to global provider
                          for (var data in parsedData) {
                            ref
                                .read(healthDataProvider.notifier)
                                .addHealthData(data);
                          }

                          // 4. Navigate to Processing Screen to run the Rule Engine
                          context.push('/processing');
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Analyze Medical Report'),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
