// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentProfileAdapter extends TypeAdapter<StudentProfile> {
  @override
  final int typeId = 18;

  @override
  StudentProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentProfile(
      university: fields[0] as String,
      major: fields[1] as String,
      year: fields[2] as String,
      studentId: fields[3] as String,
      totalStudyTimeSeconds: fields[4] == null ? 0 : fields[4] as int,
      name: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.university)
      ..writeByte(1)
      ..write(obj.major)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.studentId)
      ..writeByte(4)
      ..write(obj.totalStudyTimeSeconds)
      ..writeByte(5)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
