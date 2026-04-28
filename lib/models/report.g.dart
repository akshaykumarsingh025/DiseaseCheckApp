// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthReportAdapter extends TypeAdapter<HealthReport> {
  @override
  final int typeId = 1;

  @override
  HealthReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthReport(
      reportId: fields[0] as String,
      date: fields[1] as DateTime,
      highRiskDiseases: (fields[2] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      moderateRiskDiseases: (fields[3] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      lowRiskDiseases: (fields[4] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      abnormalValues: (fields[5] as List).cast<String>(),
      auditTrail: fields.containsKey(6)
          ? (fields[6] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : [],
      aiRefinedText: fields.containsKey(7) ? fields[7] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, HealthReport obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.reportId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.highRiskDiseases)
      ..writeByte(3)
      ..write(obj.moderateRiskDiseases)
      ..writeByte(4)
      ..write(obj.lowRiskDiseases)
      ..writeByte(5)
      ..write(obj.abnormalValues)
      ..writeByte(6)
      ..write(obj.auditTrail)
      ..writeByte(7)
      ..write(obj.aiRefinedText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
