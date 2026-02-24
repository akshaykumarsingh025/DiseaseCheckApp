import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../engine/ocr_parser.dart';

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
        });
        _processImage(_image!);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  // Reorders ML Kit blocks geometrically to fix column-reading issues
  String _reconstructRows(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return recognizedText.text;

    List<Map<String, dynamic>> allLines = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        final rect = line.boundingBox;
        allLines.add({
          'text': line.text,
          'y': rect.top + (rect.height / 2),
          'x': rect.left,
          'height': rect.height
        });
      }
    }

    // Sort vertically
    allLines.sort((a, b) => (a['y'] as double).compareTo(b['y'] as double));

    List<List<Map<String, dynamic>>> rows = [];
    if (allLines.isNotEmpty) {
      List<Map<String, dynamic>> currentRow = [allLines.first];
      double currentY = allLines.first['y'];
      double currentHeight = allLines.first['height'];

      for (int i = 1; i < allLines.length; i++) {
        final line = allLines[i];

        // Group lines that are vertically close (e.g. within half a line height)
        if ((line['y'] - currentY).abs() < (currentHeight * 0.5)) {
          currentRow.add(line);
        } else {
          rows.add(currentRow);
          currentRow = [line];
          currentY = line['y'];
          currentHeight = line['height'];
        }
      }
      rows.add(currentRow);
    }

    StringBuffer sb = StringBuffer();
    for (var row in rows) {
      // Sort items in this row left to right
      row.sort((a, b) => (a['x'] as double).compareTo(b['x'] as double));
      String rowText = row.map((e) => e['text']).join('   ');
      sb.writeln(rowText);
    }

    return sb.toString();
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      // Reconstruct aligned text to counter ML Kit's column-reading bias
      String alignedText = _reconstructRows(recognizedText);

      // 1. Analyze the text
      final flags = OcrParser.analyze(alignedText);

      // 2. Map results to initialValues map matching test definitions
      final initialValues = <String, dynamic>{};
      flags.forEach((key, value) {
        initialValues[key] = value;
      });

      // 3. Navigate to Review Screen with both parsed values and raw text
      context.push('/ocr-review', extra: {
        'values': initialValues,
        'rawText': alignedText,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
