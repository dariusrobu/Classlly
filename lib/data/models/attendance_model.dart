import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: 9)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
  @HiveField(2)
  late,
  @HiveField(3)
  excused,
}

@HiveType(typeId: 10)
class Attendance extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  AttendanceStatus status;

  Attendance({
    required this.id,
    required this.courseId,
    required this.date,
    required this.status,
  });

  factory Attendance.create({
    required String courseId,
    DateTime? date,
    AttendanceStatus status = AttendanceStatus.present,
  }) {
    return Attendance(
      id: const Uuid().v4(),
      courseId: courseId,
      date: date ?? DateTime.now(),
      status: status,
    );
  }
}
