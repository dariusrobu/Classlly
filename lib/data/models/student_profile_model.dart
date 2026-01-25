import 'package:hive/hive.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'student_profile_model.g.dart';

@HiveType(typeId: 18)
class StudentProfile extends HiveObject {
  @HiveField(0)
  String university;
  @HiveField(1)
  String major;
  @HiveField(2)
  String year;
  @HiveField(3)
  String studentId;
  @HiveField(4, defaultValue: 0)
  int totalStudyTimeSeconds;
  @HiveField(5)
  String? name;

  StudentProfile({
    this.university = '',
    this.major = '',
    this.year = '',
    this.studentId = '',
    this.totalStudyTimeSeconds = 0,
    this.name = 'Alex',
  });

  Map<String, dynamic> toJson() => {
    'university': university,
    'major': major,
    'year': year,
    'student_id': studentId,
    'total_study_time_seconds': totalStudyTimeSeconds,
    'name': name,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    university: JsonUtils.asString(json['university']),
    major: JsonUtils.asString(json['major']),
    year: JsonUtils.asString(json['year']),
    studentId: JsonUtils.asString(json['student_id']),
    totalStudyTimeSeconds: JsonUtils.asInt(json['total_study_time_seconds']),
    name: JsonUtils.asString(json['name'], defaultValue: 'Alex'),
  );
}
