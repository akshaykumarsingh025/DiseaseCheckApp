class PrescriptionMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  const PrescriptionMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      instructions: json['instructions'] as String?,
    );
  }
}

class Prescription {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String? dmcNumber;
  final DateTime appointmentDate;
  final String appointmentTime;
  final List<PrescriptionMedicine> medicines;
  final String chiefComplaint;
  final String diagnosis;
  final String? menstrualHistory;
  final String? obstetricHistory;
  final String? pastHistory;
  final String? surgicalHistory;
  final String? advice;
  final String? followUpDate;
  final DateTime createdAt;

  const Prescription({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    this.dmcNumber,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.medicines,
    required this.chiefComplaint,
    required this.diagnosis,
    this.menstrualHistory,
    this.obstetricHistory,
    this.pastHistory,
    this.surgicalHistory,
    this.advice,
    this.followUpDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'dmcNumber': dmcNumber,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'chiefComplaint': chiefComplaint,
        'diagnosis': diagnosis,
        'menstrualHistory': menstrualHistory,
        'obstetricHistory': obstetricHistory,
        'pastHistory': pastHistory,
        'surgicalHistory': surgicalHistory,
        'advice': advice,
        'followUpDate': followUpDate,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      appointmentId: json['appointmentId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      dmcNumber: json['dmcNumber'] as String?,
      appointmentDate: _parseDateTime(json['appointmentDate']),
      appointmentTime: json['appointmentTime'] as String? ?? '',
      medicines: (json['medicines'] as List?)
              ?.map((m) =>
                  PrescriptionMedicine.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          [],
      chiefComplaint: json['chiefComplaint'] as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? '',
      menstrualHistory: json['menstrualHistory'] as String?,
      obstetricHistory: json['obstetricHistory'] as String?,
      pastHistory: json['pastHistory'] as String?,
      surgicalHistory: json['surgicalHistory'] as String?,
      advice: json['advice'] as String?,
      followUpDate: json['followUpDate'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
