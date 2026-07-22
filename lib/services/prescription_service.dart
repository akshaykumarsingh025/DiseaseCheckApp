import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/prescription.dart';
import '../utils/doctor_info.dart';

class PrescriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> savePrescription(Prescription prescription) async {
    await _firestore
        .collection('prescriptions')
        .doc(prescription.appointmentId)
        .set(prescription.toJson());
  }

  static Future<Prescription?> getPrescription(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('prescriptions')
          .doc(appointmentId)
          .get();
      if (doc.exists && doc.data() != null) {
        return Prescription.fromJson(doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Prescription>> getPatientPrescriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // No orderBy here: combining where() + orderBy() on different fields
      // requires a composite index. Sort client-side instead.
      final snapshot = await _firestore
          .collection('prescriptions')
          .where('patientId', isEqualTo: user.uid)
          .get();

      final list = snapshot.docs
          .map((doc) => Prescription.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Prescription>> getDoctorPrescriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('prescriptions')
          .where('doctorId', isEqualTo: user.uid)
          .get();

      final list = snapshot.docs
          .map((doc) => Prescription.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<String> generatePrescriptionPdf(Prescription rx) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.$1,
        bold: fonts.$2,
        italic: fonts.$3,
        boldItalic: fonts.$4,
      ),
    );

    final dateStr = DateFormat('dd MMM yyyy').format(rx.appointmentDate);
    final createdStr = DateFormat('dd MMM yyyy, hh:mm a').format(rx.createdAt);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0x0F3460),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MEDICAL PRESCRIPTION',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(DoctorInfo.name,
                    style: const pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0x93C5FD))),
                pw.Text(DoctorInfo.qualification,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0x93C5FD))),
                pw.SizedBox(height: 4),
                if (rx.dmcNumber != null && rx.dmcNumber!.isNotEmpty)
                  pw.Text('DMC No: ${rx.dmcNumber}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0x93C5FD))),
                pw.SizedBox(height: 8),
                pw.Text('${DoctorInfo.phoneDisplay}  |  ${DoctorInfo.email}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0x93C5FD))),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xE5E7EB)),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PATIENT DETAILS',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0x6B7280),
                        letterSpacing: 1.5)),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text('Name: ${rx.patientName}',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        child: pw.Text('Date: $dateStr',
                            style: const pw.TextStyle(fontSize: 11))),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text('Time: ${rx.appointmentTime}',
                            style: const pw.TextStyle(fontSize: 11))),
                    pw.Expanded(
                        child: pw.Text('Rx ID: ${rx.appointmentId.substring(0, rx.appointmentId.length.clamp(0, 20))}',
                            style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (rx.chiefComplaint.isNotEmpty) ...[
            pw.Text('CHIEF COMPLAINT',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF7ED),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.chiefComplaint,
                  style: const pw.TextStyle(fontSize: 11, height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          if (rx.diagnosis.isNotEmpty) ...[
            pw.Text('DIAGNOSIS',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFEF2F2),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.diagnosis,
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xDC2626),
                      height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          if (rx.menstrualHistory != null && rx.menstrualHistory!.isNotEmpty) ...[
            pw.Text('MENSTRUAL HISTORY',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFCE7F3),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.menstrualHistory!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          if (rx.obstetricHistory != null && rx.obstetricHistory!.isNotEmpty) ...[
            pw.Text('OBSTETRIC HISTORY',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xCCFBF1),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.obstetricHistory!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          if (rx.pastHistory != null && rx.pastHistory!.isNotEmpty) ...[
            pw.Text('PAST HISTORY',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF7ED),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.pastHistory!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          if (rx.surgicalHistory != null && rx.surgicalHistory!.isNotEmpty) ...[
            pw.Text('SURGICAL HISTORY',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xEDE9FE),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.surgicalHistory!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.4)),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Text('PRESCRIBED MEDICINES',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0x6B7280),
                  letterSpacing: 1.5)),
          pw.SizedBox(height: 8),
          ...rx.medicines.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final med = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromInt(0xE5E7EB)),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0x2563EB),
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(10)),
                        ),
                        child: pw.Text('$i',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.white)),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(med.name,
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: pw.Text('Dosage: ${med.dosage}',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(
                          child: pw.Text('Frequency: ${med.frequency}',
                              style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: pw.Text('Duration: ${med.duration}',
                              style: const pw.TextStyle(fontSize: 10))),
                      if (med.instructions != null &&
                          med.instructions!.isNotEmpty)
                        pw.Expanded(
                            child: pw.Text('Notes: ${med.instructions}',
                                style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColor.fromInt(0x6B7280)))),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (rx.advice != null && rx.advice!.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('ADVICE',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0x6B7280),
                    letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xF0FDF4),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(rx.advice!,
                  style: const pw.TextStyle(fontSize: 11, height: 1.5)),
            ),
          ],
          if (rx.followUpDate != null && rx.followUpDate!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xDBEAFE),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                children: [
                  pw.Text('Follow-up: ',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(rx.followUpDate!,
                      style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromInt(0x1E40AF),
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Doctor's Signature",
                      style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0x9CA3AF))),
                  pw.SizedBox(height: 40),
                  pw.Container(
                      width: 150,
                      height: 0.5,
                      color: PdfColor.fromInt(0x374151)),
                  pw.SizedBox(height: 4),
                  pw.Text(DoctorInfo.name,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DoctorInfo.qualification,
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFCA5A5)),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              color: PdfColor.fromInt(0xFEF2F2),
            ),
            child: pw.Text(
              'This prescription is valid only with the treating doctor\'s authorization. '
              'Do not self-medicate. Consult your doctor before making any changes to the prescribed medication.',
              style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromInt(0x991B1B),
                  height: 1.4),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Generated: $createdStr',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColor.fromInt(0x9CA3AF))),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Prescription_${rx.patientName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(rx.appointmentDate)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<void> sharePrescriptionPdf(Prescription rx) async {
    final path = await generatePrescriptionPdf(rx);
    await Share.shareXFiles(
      [XFile(path)],
      subject: 'Prescription - ${rx.patientName} - ${DateFormat('dd MMM yyyy').format(rx.appointmentDate)}',
    );
  }

  static Future<(pw.Font, pw.Font, pw.Font, pw.Font)> _loadFonts() async {
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final regular = pw.Font.ttf(regularData);
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final bold = pw.Font.ttf(boldData);
    final italicData = await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');
    final italic = pw.Font.ttf(italicData);
    final boldItalicData = await rootBundle.load('assets/fonts/NotoSans-BoldItalic.ttf');
    final boldItalic = pw.Font.ttf(boldItalicData);
    return (regular, bold, italic, boldItalic);
  }
}
