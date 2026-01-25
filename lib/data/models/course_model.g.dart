// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 7;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course(
      id: fields[0] as String,
      title: fields[1] as String,
      professor: fields[2] as String,
      schedule: fields[3] as String,
      location: fields[4] as String,
      color: fields[5] as int,
      semester: fields[6] as String,
      iconCodePoint: fields[7] as int,
      credits: fields[8] as double,
      courseFrequency: fields[9] as String,
      courseDay: fields[10] as String,
      courseTime: fields[11] as String,
      seminarProfessor: fields[12] as String,
      seminarLocation: fields[13] as String,
      seminarFrequency: fields[14] as String,
      seminarDay: fields[15] as String,
      seminarTime: fields[16] as String,
      cachedAverageGrade: fields[17] == null ? 0.0 : fields[17] as double,
      cachedAttendanceRate: fields[18] == null ? 0.0 : fields[18] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.professor)
      ..writeByte(3)
      ..write(obj.schedule)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.semester)
      ..writeByte(7)
      ..write(obj.iconCodePoint)
      ..writeByte(8)
      ..write(obj.credits)
      ..writeByte(9)
      ..write(obj.courseFrequency)
      ..writeByte(10)
      ..write(obj.courseDay)
      ..writeByte(11)
      ..write(obj.courseTime)
      ..writeByte(12)
      ..write(obj.seminarProfessor)
      ..writeByte(13)
      ..write(obj.seminarLocation)
      ..writeByte(14)
      ..write(obj.seminarFrequency)
      ..writeByte(15)
      ..write(obj.seminarDay)
      ..writeByte(16)
      ..write(obj.seminarTime)
      ..writeByte(17)
      ..write(obj.cachedAverageGrade)
      ..writeByte(18)
      ..write(obj.cachedAttendanceRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
