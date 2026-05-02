import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/report.dart';
import '../models/user_profile.dart';
import '../utils/doctor_info.dart';

class PdfReportService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _italicFont;
  static pw.Font? _boldItalicFont;

  static Future<void> _loadFonts() async {
    if (_regularFont != null) return;
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    _regularFont = pw.Font.ttf(regularData);
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _boldFont = pw.Font.ttf(boldData);
    final italicData = await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');
    _italicFont = pw.Font.ttf(italicData);
    final boldItalicData = await rootBundle.load('assets/fonts/NotoSans-BoldItalic.ttf');
    _boldItalicFont = pw.Font.ttf(boldItalicData);
  }

  static String _clean(String input) {
    return input
        .replaceAll('\u2265', '>=')
        .replaceAll('\u2264', '<=')
        .replaceAll('\u2260', '!=')
        .replaceAll('\u226E', '>=')
        .replaceAll('\u226F', '<=')
        .replaceAll('\u00B5', 'u')
        .replaceAll('\u03BC', 'u')
        .replaceAll('\u00B0', ' deg')
        .replaceAll('\u00B1', '+/-')
        .replaceAll('\u00D7', 'x')
        .replaceAll('\u00F7', '/')
        .replaceAll('\u2192', '->')
        .replaceAll('\u2190', '<-')
        .replaceAll('\u2191', '^')
        .replaceAll('\u2193', 'v')
        .replaceAll('\u2194', '<->')
        .replaceAll('\u221E', 'inf')
        .replaceAll('\u2248', '~')
        .replaceAll('\u2249', '!~')
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{FE00}-\u{FE0F}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1F900}-\u{1F9FF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1FA00}-\u{1FA6F}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{1FA70}-\u{1FAFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{200D}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{FE0E}]', unicode: true), '');
  }

  static PdfColor _opacity(PdfColor color, double alpha) {
    return PdfColor(color.red, color.green, color.blue, alpha);
  }

  static const _navy = PdfColor.fromInt(0x0F172A);
  static const _accentBlue = PdfColor.fromInt(0x2563EB);
  static const _lightBlue = PdfColor.fromInt(0xDBEAFE);
  static const _paleBlue = PdfColor.fromInt(0xEFF6FF);
  static const _highRed = PdfColor.fromInt(0xDC2626);
  static const _highRedBg = PdfColor.fromInt(0xFEF2F2);
  static const _modOrange = PdfColor.fromInt(0xEA580C);
  static const _modOrangeBg = PdfColor.fromInt(0xFFF7ED);
  static const _lowGreen = PdfColor.fromInt(0x16A34A);
  static const _lowGreenBg = PdfColor.fromInt(0xF0FDF4);
  static const _abnormalPurple = PdfColor.fromInt(0x7C3AED);
  static const _abnormalPurpleBg = PdfColor.fromInt(0xFAF5FF);
  static const _grey100 = PdfColor.fromInt(0xF3F4F6);
  static const _grey200 = PdfColor.fromInt(0xE5E7EB);
  static const _grey400 = PdfColor.fromInt(0x9CA3AF);
  static const _grey500 = PdfColor.fromInt(0x6B7280);
  static const _grey700 = PdfColor.fromInt(0x374151);
  static const _grey900 = PdfColor.fromInt(0x111827);
  static const _warmBrown = PdfColor.fromInt(0x9A3412);
  static const _warmBg = PdfColor.fromInt(0xFFFBEB);
  static const _warmBorder = PdfColor.fromInt(0xFDE68A);
  static const _skyText = PdfColor.fromInt(0x93C5FD);
  static const _darkBlueText = PdfColor.fromInt(0x1E40AF);
  static const _disclaimerRed = PdfColor.fromInt(0x991B1B);
  static const _disclaimerBorder = PdfColor.fromInt(0xFCA5A5);
  static const _disclaimerBg = PdfColor.fromInt(0xFEF2F2);

  static Future<Uint8List> generateReport({
    required HealthReport report,
    UserProfile? profile,
  }) async {
    await _loadFonts();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _regularFont!,
        bold: _boldFont!,
        italic: _italicFont!,
        boldItalic: _boldItalicFont!,
      ),
    );

    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final dateStr = dateFormatter.format(report.date);

    final totalRisks = report.highRiskDiseases.length +
        report.moderateRiskDiseases.length +
        report.lowRiskDiseases.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, dateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(dateStr),
          pw.SizedBox(height: 20),

          if (profile != null) ...[
            _buildPatientInfo(profile),
            pw.SizedBox(height: 16),
          ],

          _buildSummaryBar(totalRisks, report),
          pw.SizedBox(height: 20),

          if (report.highRiskDiseases.isNotEmpty) ...[
            _buildRiskSection(
              'HIGH RISK',
              report.highRiskDiseases,
              _highRed,
              _highRedBg,
            ),
            pw.SizedBox(height: 14),
          ],

          if (report.moderateRiskDiseases.isNotEmpty) ...[
            _buildRiskSection(
              'MODERATE RISK',
              report.moderateRiskDiseases,
              _modOrange,
              _modOrangeBg,
            ),
            pw.SizedBox(height: 14),
          ],

          if (report.lowRiskDiseases.isNotEmpty) ...[
            _buildRiskSection(
              'LOW RISK',
              report.lowRiskDiseases,
              _lowGreen,
              _lowGreenBg,
            ),
            pw.SizedBox(height: 14),
          ],

          if (report.abnormalValues.isNotEmpty) ...[
            _buildAbnormalTable(report.abnormalValues),
            pw.SizedBox(height: 14),
          ],

          if (report.aiRefinedText != null && report.aiRefinedText!.isNotEmpty) ...[
            _buildAISection(report.aiRefinedText!),
            pw.SizedBox(height: 14),
          ],

          _buildDoctorCard(),
          pw.SizedBox(height: 16),

          _buildDisclaimer(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context, String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _grey200, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: const pw.BoxDecoration(
                  color: _accentBlue,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text('Health Check AI',
                  style: pw.TextStyle(fontSize: 8, color: _grey500, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Text(dateStr,
              style: const pw.TextStyle(fontSize: 8, color: _grey400)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _grey200, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by Health Check AI \u2014 Not a medical diagnosis',
              style: pw.TextStyle(fontSize: 7, color: _grey400, fontStyle: pw.FontStyle.italic)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _grey400)),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleSection(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 32,
            decoration: const pw.BoxDecoration(
              color: _accentBlue,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Risk Assessment Report',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )),
                pw.SizedBox(height: 4),
                pw.Text('Health Check AI \u2014 Comprehensive Health Risk Analysis',
                    style: const pw.TextStyle(fontSize: 10, color: _skyText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientInfo(UserProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grey200),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 12,
                decoration: const pw.BoxDecoration(
                  color: _accentBlue,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.5)),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text('PATIENT INFORMATION',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey700,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _grey200, width: 0.5),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    _buildInfoCell('Name', profile.name),
                    _buildInfoCell('Age', '${profile.age} years'),
                    _buildInfoCell('Gender', profile.gender),
                  ],
                ),
                if (profile.height != null && profile.weight != null)
                  pw.Row(
                    children: [
                      _buildInfoCell('Height', '${profile.height} cm'),
                      _buildInfoCell('Weight', '${profile.weight} kg'),
                      pw.Expanded(child: pw.Container()),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: const pw.TextStyle(fontSize: 7, color: _grey400, letterSpacing: 1)),
            pw.SizedBox(height: 3),
            pw.Text(_clean(value),
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _grey900)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryBar(int totalRisks, HealthReport report) {
    final high = report.highRiskDiseases.length;
    final mod = report.moderateRiskDiseases.length;
    final low = report.lowRiskDiseases.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RISK SUMMARY',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _grey500,
                letterSpacing: 1.5,
              )),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildStatItem('$totalRisks', 'Total', _grey900),
              pw.Container(width: 1, height: 30, color: _grey200),
              _buildStatItem('$high', 'High', _highRed),
              pw.Container(width: 1, height: 30, color: _grey200),
              _buildStatItem('$mod', 'Moderate', _modOrange),
              pw.Container(width: 1, height: 30, color: _grey200),
              _buildStatItem('$low', 'Low', _lowGreen),
              pw.Container(width: 1, height: 30, color: _grey200),
              _buildStatItem('${report.abnormalValues.length}', 'Abnormal', _abnormalPurple),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String value, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 2),
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 7, color: _grey500, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  static pw.Widget _buildRiskSection(
      String title, List<Map<String, dynamic>> items, PdfColor color, PdfColor bgColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 16,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(title,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                  letterSpacing: 1,
                )),
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: _opacity(color, 0.1),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text('${items.length}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        ...items.map((item) {
          final disease = _clean(item['disease']?.toString() ?? 'Unknown');
          final icd = item['icdCode']?.toString() ?? '';
          final score = item['riskScore'] ?? 0;
          final findings = item['findings'] as List? ?? [];

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _opacity(color, 0.25)),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 6),
                  decoration: pw.BoxDecoration(
                    color: bgColor,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(5),
                      topRight: pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '$disease${icd.isNotEmpty ? '  ($icd)' : ''}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _grey900),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: _opacity(color, 0.15),
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Text('$score%',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                ),
                if (findings.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: findings.map<pw.Widget>((f) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              margin: const pw.EdgeInsets.only(top: 4, right: 6),
                              width: 4,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                color: _opacity(color, 0.5),
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(_clean(f.toString()),
                                  style: const pw.TextStyle(fontSize: 9, color: _grey700, height: 1.4)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildAbnormalTable(List<String> findings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 16,
              decoration: const pw.BoxDecoration(
                color: _abnormalPurple,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('ABNORMAL VALUES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _abnormalPurple,
                  letterSpacing: 1,
                )),
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: _opacity(_abnormalPurple, 0.1),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Text('${findings.length}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _abnormalPurple)),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _opacity(_abnormalPurple, 0.25)),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const pw.BoxDecoration(
                  color: _abnormalPurpleBg,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(5),
                    topRight: pw.Radius.circular(5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 30,
                      child: pw.Text('#',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _abnormalPurple)),
                    ),
                    pw.Expanded(
                      child: pw.Text('Finding',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _abnormalPurple)),
                    ),
                  ],
                ),
              ),
              ...findings.asMap().entries.map((entry) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: _grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 30,
                      child: pw.Text('${entry.key + 1}',
                          style: pw.TextStyle(fontSize: 9, color: _grey400, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Expanded(
                      child: pw.Text(_clean(entry.value),
                          style: const pw.TextStyle(fontSize: 9, color: _grey700, height: 1.4)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAISection(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 16,
              decoration: const pw.BoxDecoration(
                color: _accentBlue,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('AI-POWERED EXPLANATION',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _accentBlue,
                  letterSpacing: 1,
                )),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _lightBlue),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            color: _paleBlue,
          ),
          child: pw.Text(_clean(text),
              style: const pw.TextStyle(fontSize: 9, height: 1.6, color: _darkBlueText)),
        ),
      ],
    );
  }

  static pw.Widget _buildDoctorCard() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _warmBorder),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        color: _warmBg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 12,
                decoration: const pw.BoxDecoration(
                  color: _warmBrown,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.5)),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text('CONSULT A DOCTOR',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _warmBrown,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(_clean(DoctorInfo.name),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _grey900)),
          pw.SizedBox(height: 2),
          pw.Text(_clean(DoctorInfo.qualification),
              style: const pw.TextStyle(fontSize: 9, color: _warmBrown)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _warmBorder, width: 0.5),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Text('Phone: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grey700)),
                    pw.Text(DoctorInfo.phoneDisplay, style: const pw.TextStyle(fontSize: 9, color: _grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Email: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grey700)),
                    pw.Expanded(child: pw.Text(_clean(DoctorInfo.email), style: const pw.TextStyle(fontSize: 9, color: _accentBlue))),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Website: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _grey700)),
                    pw.Expanded(child: pw.Text(DoctorInfo.website, style: const pw.TextStyle(fontSize: 9, color: _accentBlue))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _disclaimerBorder),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        color: _disclaimerBg,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2, right: 8),
            width: 6,
            height: 6,
            decoration: const pw.BoxDecoration(
              color: _highRed,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DISCLAIMER',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _highRed,
                      letterSpacing: 1,
                    )),
                pw.SizedBox(height: 4),
                pw.Text(
                  'This report is generated by an AI-powered health screening tool for informational purposes only. '
                  'It is NOT a medical diagnosis. Always consult a qualified healthcare provider for medical decisions. '
                  'Risk scores are based on established clinical guidelines and may not account for all individual factors.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: _disclaimerRed,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
