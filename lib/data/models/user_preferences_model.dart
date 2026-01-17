import 'package:hive/hive.dart';

part 'user_preferences_model.g.dart';

@HiveType(typeId: 13)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String themeMode; // 'system', 'light', 'dark'
  @HiveField(1)
  int accentColor;
  @HiveField(2)
  double fontSize;
  @HiveField(3)
  bool highContrast;
  @HiveField(4)
  bool syncEnabled;

  UserPreferences({
    this.themeMode = 'system',
    this.accentColor = 0xFF8B5CF6, // Primary Purple
    this.fontSize = 16.0,
    this.highContrast = false,
    this.syncEnabled = false,
  });
}
