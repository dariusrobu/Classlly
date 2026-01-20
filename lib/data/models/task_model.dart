import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 6)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? description;
  @HiveField(3)
  bool isCompleted;
  @HiveField(4)
  DateTime? dueDate;
  @HiveField(5)
  String? category; // e.g., 'Science', 'Math'
  @HiveField(6)
  double progress; // 0.0 to 1.0
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  String? courseId;
  @HiveField(9)
  int priority; // 0: Low, 1: Medium, 2: High
  @HiveField(10)
  DateTime? reminderTime;
  @HiveField(11, defaultValue: false)
  bool isDeleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.category,
    this.progress = 0.0,
    required this.createdAt,
    this.courseId,
    this.priority = 1,
    this.reminderTime,
    this.isDeleted = false,
  });

  factory Task.create({
    required String title,
    String? description,
    DateTime? dueDate,
    String? category,
    String? courseId,
    int priority = 1,
    DateTime? reminderTime,
  }) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      category: category,
      createdAt: DateTime.now(),
      courseId: courseId,
      priority: priority,
      reminderTime: reminderTime,
      isDeleted: false,
    );
  }
}
