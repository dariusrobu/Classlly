import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  });

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

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}
