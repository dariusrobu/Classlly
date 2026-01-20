// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 12;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] as String,
      title: fields[1] as String,
      parentId: fields[2] as String?,
      type: fields[3] as FolderType,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      isDeleted: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FolderTypeAdapter extends TypeAdapter<FolderType> {
  @override
  final int typeId = 11;

  @override
  FolderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FolderType.notebook;
      case 1:
        return FolderType.resource;
      default:
        return FolderType.notebook;
    }
  }

  @override
  void write(BinaryWriter writer, FolderType obj) {
    switch (obj) {
      case FolderType.notebook:
        writer.writeByte(0);
        break;
      case FolderType.resource:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
