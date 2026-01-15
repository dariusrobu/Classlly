// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrokePointAdapter extends TypeAdapter<StrokePoint> {
  @override
  final int typeId = 0;

  @override
  StrokePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrokePoint(
      x: fields[0] as double,
      y: fields[1] as double,
      pressure: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StrokePoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.pressure);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeAdapter extends TypeAdapter<Stroke> {
  @override
  final int typeId = 1;

  @override
  Stroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stroke(
      points: (fields[0] as List).cast<StrokePoint>(),
      color: fields[1] as int,
      width: fields[2] as double,
      createdAt: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Stroke obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TextBlockAdapter extends TypeAdapter<TextBlock> {
  @override
  final int typeId = 2;

  @override
  TextBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextBlock(
      id: fields[0] as String,
      text: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      createdAt: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TextBlock obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotebookAdapter extends TypeAdapter<Notebook> {
  @override
  final int typeId = 4;

  @override
  Notebook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Notebook(
      id: fields[0] as String,
      title: fields[1] as String,
      color: fields[2] as int,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Notebook obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotebookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 3;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      strokes: (fields[2] as List).cast<Stroke>(),
      textBlocks: (fields[3] as List).cast<TextBlock>(),
      audioPath: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      notebookId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.strokes)
      ..writeByte(3)
      ..write(obj.textBlocks)
      ..writeByte(4)
      ..write(obj.audioPath)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.notebookId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
