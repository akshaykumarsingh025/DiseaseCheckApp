import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pendingPayment,
  booked,
  confirmed,
  started,
  joined,
  ongoing,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromString(String? value) {
    switch (value) {
      case 'pending_payment':
        return AppointmentStatus.pendingPayment;
      case 'booked':
        return AppointmentStatus.booked;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'started':
        return AppointmentStatus.started;
      case 'joined':
        return AppointmentStatus.joined;
      case 'ongoing':
        return AppointmentStatus.ongoing;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.booked;
    }
  }

  String toDbString() {
    switch (this) {
      case AppointmentStatus.pendingPayment:
        return 'pending_payment';
      case AppointmentStatus.booked:
        return 'booked';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.started:
        return 'started';
      case AppointmentStatus.joined:
        return 'joined';
      case AppointmentStatus.ongoing:
        return 'ongoing';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  bool get isActive => this == AppointmentStatus.booked ||
      this == AppointmentStatus.confirmed ||
      this == AppointmentStatus.pendingPayment;

  bool get isInProgress => this == AppointmentStatus.started ||
      this == AppointmentStatus.joined ||
      this == AppointmentStatus.ongoing;
}

class Appointment {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? paymentId;
  final String? orderId;
  final int amount;
  final String meetingId;
  final DateTime createdAt;

  Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'booked',
    this.paymentId,
    this.orderId,
    this.amount = 111,
    required this.meetingId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive {
    if (status == 'cancelled' || status == 'completed') return false;
    final now = DateTime.now();
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startDateTime = DateTime(
      date.year, date.month, date.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );
    final endDateTime = DateTime(
      date.year, date.month, date.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );
    final bufferStart = startDateTime.subtract(const Duration(minutes: 5));
    return now.isAfter(bufferStart) && now.isBefore(endDateTime);
  }

  bool get isCompleted {
    final endParts = endTime.split(':');
    final endDateTime = DateTime(
      date.year, date.month, date.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );
    return DateTime.now().isAfter(endDateTime) || status == 'completed';
  }

  bool get isUpcoming => !isCompleted && !isActive && status != 'cancelled';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointmentId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      doctorId: json['doctorId'] as String,
      date: _parseDateTime(json['date']),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String? ?? 'booked',
      paymentId: json['paymentId'] as String?,
      orderId: json['orderId'] as String?,
      amount: json['amount'] as int? ?? 111,
      meetingId: json['meetingId'] as String,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'meetingId': meetingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? status,
    String? paymentId,
    String? orderId,
  }) {
    return Appointment(
      appointmentId: appointmentId,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ?? this.orderId,
      amount: amount,
      meetingId: meetingId,
      createdAt: createdAt,
    );
  }
}
