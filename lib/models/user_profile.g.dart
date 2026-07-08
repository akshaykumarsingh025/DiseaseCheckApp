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
      height: fields[3] as double?,
      weight: fields[4] as double?,
      phone: fields[5] as String?,
      menstrualCycleLength: fields[6] as int?,
      cycleRegularity: fields[7] as String?,
      periodPainScore: fields[8] as int?,
      reproductiveHistory: fields[9] as String?,
      profileId: fields[10] as String?,
      relation: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.reproductiveHistory)
      ..writeByte(10)
      ..write(obj.profileId)
      ..writeByte(11)
      ..write(obj.relation);
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
