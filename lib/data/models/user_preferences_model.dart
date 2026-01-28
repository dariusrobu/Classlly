import 'package:hive/hive.dart';
import 'package:classlly/core/utils/json_utils.dart';

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
  @HiveField(5, defaultValue: [])
  List<int> savedColors;
  @HiveField(6, defaultValue: true)
  bool lectureReminders;
  @HiveField(7, defaultValue: true)
  bool taskDeadlines;
  @HiveField(8, defaultValue: false)
  bool appUpdates;
  @HiveField(9, defaultValue: false)
  bool hasCompletedOnboarding;

  @HiveField(10)
  DateTime? lastSyncTimestamp;

  UserPreferences({
    this.themeMode = 'system',
    this.accentColor = 0xFF8B5CF6, // Primary Purple
    this.fontSize = 16.0,
    this.highContrast = false,
    this.syncEnabled = false,
    this.savedColors = const [],
    this.lectureReminders = true,
    this.taskDeadlines = true,
    this.appUpdates = false,
    this.hasCompletedOnboarding = false,
    this.lastSyncTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'theme_mode': themeMode,
    'accent_color': accentColor,
    'font_size': fontSize,
    'high_contrast': highContrast,
    'sync_enabled': syncEnabled,
    'saved_colors': savedColors,
    'lecture_reminders': lectureReminders,
    'task_deadlines': taskDeadlines,
    'app_updates': appUpdates,
    'has_completed_onboarding': hasCompletedOnboarding,
    'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
  };

  factory UserPreferences.fromJson(
    Map<String, dynamic> json,
  ) => UserPreferences(
    themeMode: JsonUtils.asString(json['theme_mode'], defaultValue: 'system'),
    accentColor: JsonUtils.asInt(
      json['accent_color'],
      defaultValue: 0xFF8B5CF6,
    ),
    fontSize: JsonUtils.asDouble(json['font_size'], defaultValue: 16.0),
    highContrast: JsonUtils.asBool(json['high_contrast']),
    syncEnabled: JsonUtils.asBool(json['sync_enabled']),
    savedColors: JsonUtils.asList(json['saved_colors'], (e) => e as int),
    lectureReminders: JsonUtils.asBool(
      json['lecture_reminders'],
      defaultValue: true,
    ),
    taskDeadlines: JsonUtils.asBool(json['task_deadlines'], defaultValue: true),
    appUpdates: JsonUtils.asBool(json['app_updates']),
    hasCompletedOnboarding: JsonUtils.asBool(json['has_completed_onboarding']),
    lastSyncTimestamp: json['last_sync_timestamp'] != null
        ? JsonUtils.asDateTime(json['last_sync_timestamp'])
        : null,
  );
}
