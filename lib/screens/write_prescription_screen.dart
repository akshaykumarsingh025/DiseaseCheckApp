import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/prescription.dart';
import '../services/prescription_service.dart';
import '../utils/doctor_info.dart';

class WritePrescriptionScreen extends StatefulWidget {
  final Appointment appointment;
  const WritePrescriptionScreen({super.key, required this.appointment});

  @override
  State<WritePrescriptionScreen> createState() => _WritePrescriptionScreenState();
}

class _WritePrescriptionScreenState extends State<WritePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _adviceCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();

  final List<_MedicineRow> _medicines = [_MedicineRow()];

  bool _isSaving = false;
  bool _isEditing = false;
  Prescription? _existingRx;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final rx = await PrescriptionService.getPrescription(widget.appointment.appointmentId);
    if (rx != null && mounted) {
      setState(() {
        _existingRx = rx;
        _isEditing = true;
        _chiefComplaintCtrl.text = rx.chiefComplaint;
        _diagnosisCtrl.text = rx.diagnosis;
        _adviceCtrl.text = rx.advice ?? '';
        _followUpCtrl.text = rx.followUpDate ?? '';
        _medicines.clear();
        for (var med in rx.medicines) {
          _medicines.add(_MedicineRow(
            nameCtrl: TextEditingController(text: med.name),
            dosageCtrl: TextEditingController(text: med.dosage),
            frequencyCtrl: TextEditingController(text: med.frequency),
            durationCtrl: TextEditingController(text: med.duration),
            instructionsCtrl: TextEditingController(text: med.instructions ?? ''),
          ));
        }
      });
    }
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    _diagnosisCtrl.dispose();
    _adviceCtrl.dispose();
    _followUpCtrl.dispose();
    for (var m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Prescription' : 'Write Prescription'),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: _savePrescription,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPatientCard(isDark),
              const SizedBox(height: 16),
              _buildSectionTitle('Chief Complaint', Icons.record_voice_over, Colors.orange),
              TextFormField(
                controller: _chiefComplaintCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lower abdominal pain since 3 days',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Diagnosis', Icons.medical_services, Colors.red),
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. PCOS, UTI, Iron Deficiency Anemia',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSectionTitle('Medicines', Icons.medication, Colors.blue),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: () => setState(() => _medicines.add(_MedicineRow())),
                    icon: const Icon(Icons.add, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ],
              ),
              ..._medicines.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blue.shade100,
                              child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: med.nameCtrl,
                                decoration: const InputDecoration(labelText: 'Medicine Name', isDense: true, border: OutlineInputBorder()),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            if (_medicines.length > 1)
                              IconButton(
                                onPressed: () => setState(() {
                                  med.dispose();
                                  _medicines.removeAt(i);
                                }),
                                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: med.dosageCtrl,
                                decoration: const InputDecoration(labelText: 'Dosage', isDense: true, border: OutlineInputBorder(), hintText: 'e.g. 500mg'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: med.frequencyCtrl,
                                decoration: const InputDecoration(labelText: 'Frequency', isDense: true, border: OutlineInputBorder(), hintText: 'e.g. Twice daily'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: med.durationCtrl,
                                decoration: const InputDecoration(labelText: 'Duration', isDense: true, border: OutlineInputBorder(), hintText: 'e.g. 5 days'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: med.instructionsCtrl,
                                decoration: const InputDecoration(labelText: 'Instructions (opt)', isDense: true, border: OutlineInputBorder(), hintText: 'e.g. After food'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              _buildSectionTitle('Advice', Icons.tips_and_updates, Colors.green),
              TextFormField(
                controller: _adviceCtrl,
                decoration: const InputDecoration(
                  hintText: 'Diet, lifestyle, and general advice',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Follow-up Date', Icons.event, Colors.purple),
              TextFormField(
                controller: _followUpCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. After 7 days, 15 Aug 2026',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _savePrescription,
                  icon: const Icon(Icons.save),
                  label: Text(_isEditing ? 'Update Prescription' : 'Save Prescription', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.pink.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 22, backgroundColor: Colors.pink.shade100, child: Icon(Icons.person, color: Colors.pink.shade700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.appointment.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${DateFormat('dd MMM yyyy').format(widget.appointment.date)} | ${widget.appointment.startTime} - ${widget.appointment.endTime}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final medicines = _medicines.map((m) => PrescriptionMedicine(
            name: m.nameCtrl.text.trim(),
            dosage: m.dosageCtrl.text.trim(),
            frequency: m.frequencyCtrl.text.trim(),
            duration: m.durationCtrl.text.trim(),
            instructions: m.instructionsCtrl.text.trim().isEmpty ? null : m.instructionsCtrl.text.trim(),
          )).toList();

      final prescription = Prescription(
        appointmentId: widget.appointment.appointmentId,
        patientId: widget.appointment.patientId,
        patientName: widget.appointment.patientName,
        doctorId: widget.appointment.doctorId,
        doctorName: DoctorInfo.name,
        appointmentDate: widget.appointment.date,
        appointmentTime: '${widget.appointment.startTime} - ${widget.appointment.endTime}',
        medicines: medicines,
        chiefComplaint: _chiefComplaintCtrl.text.trim(),
        diagnosis: _diagnosisCtrl.text.trim(),
        advice: _adviceCtrl.text.trim().isEmpty ? null : _adviceCtrl.text.trim(),
        followUpDate: _followUpCtrl.text.trim().isEmpty ? null : _followUpCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await PrescriptionService.savePrescription(prescription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Prescription updated!' : 'Prescription saved!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MedicineRow {
  final TextEditingController nameCtrl;
  final TextEditingController dosageCtrl;
  final TextEditingController frequencyCtrl;
  final TextEditingController durationCtrl;
  final TextEditingController instructionsCtrl;

  _MedicineRow({
    TextEditingController? nameCtrl,
    TextEditingController? dosageCtrl,
    TextEditingController? frequencyCtrl,
    TextEditingController? durationCtrl,
    TextEditingController? instructionsCtrl,
  })  : nameCtrl = nameCtrl ?? TextEditingController(),
        dosageCtrl = dosageCtrl ?? TextEditingController(),
        frequencyCtrl = frequencyCtrl ?? TextEditingController(),
        durationCtrl = durationCtrl ?? TextEditingController(),
        instructionsCtrl = instructionsCtrl ?? TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    durationCtrl.dispose();
    instructionsCtrl.dispose();
  }
}
