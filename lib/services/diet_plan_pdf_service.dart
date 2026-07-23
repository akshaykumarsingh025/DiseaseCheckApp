import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../utils/doctor_info.dart';

/// Builds a compact, clinic-branded PDF of an AI diet & lifestyle plan.
///
/// The layout is intentionally dense (small fonts, tight spacing, two-column
/// bullet flow) so a typical plan fits on a single A4 page, like a
/// prescription. Very long plans still flow safely onto a second page.
class DietPlanPdfService {
  DietPlanPdfService._();

  static Future<String> generate({
    required String planText,
    required String categoryTitle,
    String? patientName,
    String? age,
    String? gender,
    String? height,
    String? weight,
    bool isDiabetic = false,
  }) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.$1,
        bold: fonts.$2,
        italic: fonts.$3,
        boldItalic: fonts.$4,
      ),
    );

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final sections = _parsePlan(planText);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 22),
        build: (context) => [
          _header(categoryTitle),
          pw.SizedBox(height: 8),
          _infoBar(
              patientName, age, gender, height, weight, isDiabetic, dateStr),
          pw.SizedBox(height: 8),
          ..._sectionWidgets(sections),
          pw.SizedBox(height: 8),
          _footer(dateStr),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safeName =
        (patientName ?? 'DietPlan').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final fileName =
        'DietPlan_${safeName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<void> share({
    required String planText,
    required String categoryTitle,
    String? patientName,
    String? age,
    String? gender,
    String? height,
    String? weight,
    bool isDiabetic = false,
  }) async {
    final path = await generate(
      planText: planText,
      categoryTitle: categoryTitle,
      patientName: patientName,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      isDiabetic: isDiabetic,
    );
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Diet & Lifestyle Plan - ${DoctorInfo.name}',
    );
  }

  // ── PDF building blocks ────────────────────────────────────────────────

  static pw.Widget _header(String categoryTitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0F3460),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DIET & LIFESTYLE PLAN',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                    pw.SizedBox(height: 2),
                    pw.Text(categoryTitle,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColor.fromInt(0xFF93C5FD))),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(DoctorInfo.name,
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.Text(DoctorInfo.qualification,
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColor.fromInt(0xFF93C5FD))),
                  pw.Text('DMC No: ${DoctorInfo.dmcNumber}',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColor.fromInt(0xFF93C5FD))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(
              height: 1,
              thickness: 0.5,
              color: const PdfColor.fromInt(0xFF3B5B87)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DoctorInfo.address}   •   ${DoctorInfo.phoneDisplay}   •   ${DoctorInfo.website}',
            style:
                const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFC7D8F0)),
          ),
          pw.Text(
            '${DoctorInfo.clinicHoursWeekday}   •   ${DoctorInfo.clinicHoursSunday}',
            style:
                const pw.TextStyle(fontSize: 7, color: PdfColor.fromInt(0xFFC7D8F0)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoBar(String? name, String? age, String? gender,
      String? height, String? weight, bool isDiabetic, String dateStr) {
    final bmi = _bmi(height, weight);
    final parts = <String>[];
    if (name != null && name.trim().isNotEmpty) parts.add('Name: ${name.trim()}');
    final ag = <String>[];
    if (age != null && age.trim().isNotEmpty) ag.add('${_clean(age)} yrs');
    if (gender != null && gender.trim().isNotEmpty) ag.add(gender.trim());
    if (ag.isNotEmpty) parts.add(ag.join(', '));
    if (height != null && height.trim().isNotEmpty) {
      parts.add('Ht: ${_clean(height)} cm');
    }
    if (weight != null && weight.trim().isNotEmpty) {
      parts.add('Wt: ${_clean(weight)} kg');
    }
    if (bmi != null) parts.add('BMI: $bmi');
    if (isDiabetic) parts.add('Diabetic');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              parts.isEmpty ? 'Personalized plan' : parts.join('   •   '),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('Date: $dateStr',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromInt(0xFF6B7280))),
        ],
      ),
    );
  }

  static List<pw.Widget> _sectionWidgets(List<_Section> sections) {
    final widgets = <pw.Widget>[];
    for (final section in sections) {
      if (section.title.isNotEmpty) {
        widgets.add(pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFF4FB),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(section.title.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0F3460),
                  letterSpacing: 0.5)),
        ));
      }
      for (final line in section.lines) {
        if (line.isSubheading) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3, bottom: 1),
            child: pw.Text(line.text,
                style: pw.TextStyle(
                    fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          ));
        } else if (line.bullet) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4, bottom: 1.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, right: 5),
                  child: pw.Container(
                      width: 2.5,
                      height: 2.5,
                      decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF0F3460),
                          shape: pw.BoxShape.circle)),
                ),
                pw.Expanded(
                  child: pw.Text(line.text,
                      style: const pw.TextStyle(fontSize: 8.5, height: 1.25)),
                ),
              ],
            ),
          ));
        } else {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1.5),
            child: pw.Text(line.text,
                style: const pw.TextStyle(fontSize: 8.5, height: 1.25)),
          ));
        }
      }
    }
    return widgets;
  }

  static pw.Widget _footer(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFEF2F2),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFFCA5A5)),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'This AI-generated diet & lifestyle plan is a general guide, not a substitute for '
            'professional medical advice. Please consult ${DoctorInfo.name} '
            '(${DoctorInfo.phoneDisplay}) before making major dietary or lifestyle changes.',
            style: const pw.TextStyle(
                fontSize: 7.5, color: PdfColor.fromInt(0xFF991B1B), height: 1.35),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Generated by DiseaseCheck • $dateStr',
            style: const pw.TextStyle(
                fontSize: 6.5, color: PdfColor.fromInt(0xFF9CA3AF))),
      ],
    );
  }

  // ── Plan text parsing ──────────────────────────────────────────────────

  static List<_Section> _parsePlan(String raw) {
    final sections = <_Section>[];
    var current = _Section('');
    sections.add(current);

    for (var rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final heading = _asHeading(line);
      if (heading != null) {
        // Skip a duplicate empty leading section.
        if (current.title.isEmpty && current.lines.isEmpty) {
          sections.removeLast();
        }
        current = _Section(heading);
        sections.add(current);
        continue;
      }

      if (line.startsWith('-') ||
          line.startsWith('*') ||
          line.startsWith('•') ||
          line.startsWith('·')) {
        final text = _clean(line.replaceFirst(RegExp(r'^[-*•·]+\s*'), ''));
        if (text.isNotEmpty) current.lines.add(_Line(text, bullet: true));
      } else {
        final text = _clean(line);
        if (text.isEmpty) continue;
        // A short line ending with ':' reads as a sub-heading.
        final isSub = text.length <= 48 && text.endsWith(':');
        current.lines.add(_Line(text, isSubheading: isSub));
      }
    }

    // Drop empty leading section.
    sections.removeWhere((s) => s.title.isEmpty && s.lines.isEmpty);
    return sections;
  }

  /// Detects a section heading like `** DIET PLAN **`, `**Diet Plan**`,
  /// `## Diet Plan`, or a short ALL-CAPS line.
  static String? _asHeading(String line) {
    final starred = RegExp(r'^\*{1,3}\s*(.+?)\s*\*{1,3}$').firstMatch(line);
    if (starred != null) {
      final inner = starred.group(1)!.trim();
      if (inner.isNotEmpty && inner.length <= 60) return inner;
    }
    final hashed = RegExp(r'^#{1,4}\s*(.+?)\s*#*$').firstMatch(line);
    if (hashed != null) return hashed.group(1)!.trim();
    // ALL CAPS short line (allow spaces, &, /).
    final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length >= 3 &&
        line.length <= 40 &&
        line == line.toUpperCase() &&
        !line.startsWith('-')) {
      return line.replaceAll(RegExp(r'[*#:]'), '').trim();
    }
    return null;
  }

  /// Strips stray markdown emphasis characters.
  static String _clean(String s) {
    return s
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'__'), '')
        .replaceAll(RegExp(r'`'), '')
        .trim();
  }

  static String? _bmi(String? height, String? weight) {
    final h = double.tryParse(_clean(height ?? ''));
    final w = double.tryParse(_clean(weight ?? ''));
    if (h == null || w == null || h <= 0 || w <= 0) return null;
    final m = h / 100.0;
    final bmi = w / (m * m);
    if (bmi.isNaN || bmi.isInfinite || bmi <= 0 || bmi > 200) return null;
    return bmi.toStringAsFixed(1);
  }

  static Future<(pw.Font, pw.Font, pw.Font, pw.Font)> _loadFonts() async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final italic =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Italic.ttf'));
    final boldItalic = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-BoldItalic.ttf'));
    return (regular, bold, italic, boldItalic);
  }
}

class _Section {
  final String title;
  final List<_Line> lines = [];
  _Section(this.title);
}

class _Line {
  final String text;
  final bool bullet;
  final bool isSubheading;
  _Line(this.text, {this.bullet = false, this.isSubheading = false});
}
