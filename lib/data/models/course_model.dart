import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'course_model.g.dart';

@HiveType(typeId: 7)
class Course extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String professor; // Course Teacher
  @HiveField(3)
  String schedule; // Legacy: Course Day + Time
  @HiveField(4)
  String location; // Course Room
  @HiveField(5)
  int color;
  @HiveField(6)
  String semester;
  @HiveField(7)
  int iconCodePoint;

  // New Fields
  @HiveField(8)
  double credits;

  @HiveField(9)
  String courseFrequency;
  @HiveField(10)
  String courseDay;
  @HiveField(11)
  String courseTime;

  @HiveField(12)
  String seminarProfessor;
  @HiveField(13)
  String seminarLocation;
  @HiveField(14)
  String seminarFrequency;
  @HiveField(15)
  String seminarDay;
  @HiveField(16)
  String seminarTime;

  @HiveField(17, defaultValue: 0.0)
  double cachedAverageGrade;

  @HiveField(18, defaultValue: 0.0)
  double cachedAttendanceRate;

  Course({
    required this.id,
    required this.title,
    this.professor = '',
    this.schedule = '',
    this.location = '',
    required this.color,
    this.semester = '',
    required this.iconCodePoint,
    this.credits = 0.0,
    this.courseFrequency = '',
    this.courseDay = '',
    this.courseTime = '',
    this.seminarProfessor = '',
    this.seminarLocation = '',
    this.seminarFrequency = '',
    this.seminarDay = '',
    this.seminarTime = '',
    this.cachedAverageGrade = 0.0,
    this.cachedAttendanceRate = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'professor': professor,
    'schedule': schedule,
    'location': location,
    'color': color,
    'semester': semester,
    'icon_code': iconCodePoint,
    'credits': credits,
    'course_frequency': courseFrequency,
    'course_day': courseDay,
    'course_time': courseTime,
    'seminar_professor': seminarProfessor,
    'seminar_location': seminarLocation,
    'seminar_frequency': seminarFrequency,
    'seminar_day': seminarDay,
    'seminar_time': seminarTime,
    'cached_average_grade': cachedAverageGrade,
    'cached_attendance_rate': cachedAttendanceRate,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title'], defaultValue: 'Untitled Course'),
    professor: JsonUtils.asString(json['professor']),
    schedule: JsonUtils.asString(json['schedule']),
    location: JsonUtils.asString(json['location']),
    color: JsonUtils.asInt(json['color'], defaultValue: 0xFF3B82F6),
    semester: JsonUtils.asString(json['semester']),
    iconCodePoint: JsonUtils.asInt(json['icon_code'], defaultValue: 0xe559),
    credits: JsonUtils.asDouble(json['credits']),
    courseFrequency: JsonUtils.asString(json['course_frequency']),
    courseDay: JsonUtils.asString(json['course_day']),
    courseTime: JsonUtils.asString(json['course_time']),
    seminarProfessor: JsonUtils.asString(json['seminar_professor']),
    seminarLocation: JsonUtils.asString(json['seminar_location']),
    seminarFrequency: JsonUtils.asString(json['seminar_frequency']),
    seminarDay: JsonUtils.asString(json['seminar_day']),
    seminarTime: JsonUtils.asString(json['seminar_time']),
    cachedAverageGrade: JsonUtils.asDouble(json['cached_average_grade']),
    cachedAttendanceRate: JsonUtils.asDouble(json['cached_attendance_rate']),
  );

  factory Course.create({
    required String title,
    String professor = '',
    String schedule = '',
    String location = '',
    Color color = Colors.blue,
    String semester = '',
    IconData icon = Icons.book,
    double credits = 0.0,
    String courseFrequency = '',
    String courseDay = '',
    String courseTime = '',
    String seminarProfessor = '',
    String seminarLocation = '',
    String seminarFrequency = '',
    String seminarDay = '',
    String seminarTime = '',
  }) {
    return Course(
      id: const Uuid().v4(),
      title: title,
      professor: professor,
      schedule: schedule,
      location: location,
      color: color.toARGB32(),
      semester: semester,
      iconCodePoint: icon.codePoint,
      credits: credits,
      courseFrequency: courseFrequency,
      courseDay: courseDay,
      courseTime: courseTime,
      seminarProfessor: seminarProfessor,
      seminarLocation: seminarLocation,
      seminarFrequency: seminarFrequency,
      seminarDay: seminarDay,
      seminarTime: seminarTime,
    );
  }

  /// Static map of allowed course icons for tree-shaking compatibility.
  /// Add new icons here as needed.
  static const Map<int, IconData> _iconMap = {
    0xe0ee: Icons.book,           // Default
    0xe559: Icons.school,
    0xf06c8: Icons.science,
    0xe43a: Icons.calculate,
    0xe25a: Icons.history_edu,
    0xe3dc: Icons.palette,
    0xe3b3: Icons.music_note,
    0xe57e: Icons.sports_soccer,
    0xe8f4: Icons.psychology,
    0xe54f: Icons.language,
    0xe02c: Icons.computer,
    0xe23a: Icons.gavel,
    0xe548: Icons.local_hospital,
    0xf06bb: Icons.engineering,
    0xe0ba: Icons.attach_money,
    0xef5d: Icons.architecture,
    0xe5c3: Icons.public,
    0xf06c1: Icons.biotech,
  };

  IconData get icon => _iconMap[iconCodePoint] ?? Icons.book;
}
