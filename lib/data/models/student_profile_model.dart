import 'package:hive/hive.dart';

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
}
