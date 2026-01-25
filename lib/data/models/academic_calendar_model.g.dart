// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_calendar_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AcademicPeriodAdapter extends TypeAdapter<AcademicPeriod> {
  @override
  final int typeId = 15;

  @override
  AcademicPeriod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademicPeriod(
      id: fields[0] as String,
      name: fields[1] as String,
      startDate: fields[2] as DateTime,
      endDate: fields[3] as DateTime,
      type: fields[4] as AcademicPeriodType,
    );
  }

  @override
  void write(BinaryWriter writer, AcademicPeriod obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.endDate)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AcademicEventAdapter extends TypeAdapter<AcademicEvent> {
  @override
  final int typeId = 17;

  @override
  AcademicEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AcademicEvent(
      id: fields[0] as String,
      name: fields[1] as String,
      date: fields[2] as DateTime,
      type: fields[3] as AcademicEventType,
    );
  }

  @override
  void write(BinaryWriter writer, AcademicEvent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AcademicPeriodTypeAdapter extends TypeAdapter<AcademicPeriodType> {
  @override
  final int typeId = 14;

  @override
  AcademicPeriodType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AcademicPeriodType.teaching;
      case 1:
        return AcademicPeriodType.exam;
      case 2:
        return AcademicPeriodType.session;
      case 3:
        return AcademicPeriodType.retake;
      case 4:
        return AcademicPeriodType.holiday;
      default:
        return AcademicPeriodType.teaching;
    }
  }

  @override
  void write(BinaryWriter writer, AcademicPeriodType obj) {
    switch (obj) {
      case AcademicPeriodType.teaching:
        writer.writeByte(0);
        break;
      case AcademicPeriodType.exam:
        writer.writeByte(1);
        break;
      case AcademicPeriodType.session:
        writer.writeByte(2);
        break;
      case AcademicPeriodType.retake:
        writer.writeByte(3);
        break;
      case AcademicPeriodType.holiday:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicPeriodTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AcademicEventTypeAdapter extends TypeAdapter<AcademicEventType> {
  @override
  final int typeId = 16;

  @override
  AcademicEventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AcademicEventType.holiday;
      case 1:
        return AcademicEventType.freeDay;
      default:
        return AcademicEventType.holiday;
    }
  }

  @override
  void write(BinaryWriter writer, AcademicEventType obj) {
    switch (obj) {
      case AcademicEventType.holiday:
        writer.writeByte(0);
        break;
      case AcademicEventType.freeDay:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademicEventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
