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
      highRiskDiseases: (fields[2] as List).cast<dynamic>(),
      moderateRiskDiseases: (fields[3] as List).cast<dynamic>(),
      lowRiskDiseases: (fields[4] as List).cast<dynamic>(),
      abnormalValues: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthReport obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.abnormalValues);
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
