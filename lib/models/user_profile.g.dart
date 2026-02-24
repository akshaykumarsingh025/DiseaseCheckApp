// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      age: fields[1] as int,
      gender: fields[2] as String,
      height: fields.containsKey(3) ? fields[3] as double? : null,
      weight: fields.containsKey(4) ? fields[4] as double? : null,
      phone: fields.containsKey(5) ? fields[5] as String? : null,
      menstrualCycleLength: fields.containsKey(6) ? fields[6] as int? : null,
      cycleRegularity: fields.containsKey(7) ? fields[7] as String? : null,
      periodPainScore: fields.containsKey(8) ? fields[8] as int? : null,
      reproductiveHistory: fields.containsKey(9) ? fields[9] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.menstrualCycleLength)
      ..writeByte(7)
      ..write(obj.cycleRegularity)
      ..writeByte(8)
      ..write(obj.periodPainScore)
      ..writeByte(9)
      ..write(obj.reproductiveHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
