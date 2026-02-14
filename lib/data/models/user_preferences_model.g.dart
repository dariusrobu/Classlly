// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 13;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      themeMode: fields[0] as String,
      accentColor: fields[1] as int,
      fontSize: fields[2] as double,
      highContrast: fields[3] as bool,
      syncEnabled: fields[4] as bool,
      savedColors: fields[5] == null ? [] : (fields[5] as List).cast<int>(),
      lectureReminders: fields[6] == null ? true : fields[6] as bool,
      taskDeadlines: fields[7] == null ? true : fields[7] as bool,
      appUpdates: fields[8] == null ? false : fields[8] as bool,
      hasCompletedOnboarding: fields[9] == null ? false : fields[9] as bool,
      lastSyncTimestamp: fields[10] as DateTime?,
      schemaVersion: fields[11] == null ? 0 : fields[11] as int,
      cloudProvider: fields[12] == null ? 'none' : fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.accentColor)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.highContrast)
      ..writeByte(4)
      ..write(obj.syncEnabled)
      ..writeByte(5)
      ..write(obj.savedColors)
      ..writeByte(6)
      ..write(obj.lectureReminders)
      ..writeByte(7)
      ..write(obj.taskDeadlines)
      ..writeByte(8)
      ..write(obj.appUpdates)
      ..writeByte(9)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(10)
      ..write(obj.lastSyncTimestamp)
      ..writeByte(11)
      ..write(obj.schemaVersion)
      ..writeByte(12)
      ..write(obj.cloudProvider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
