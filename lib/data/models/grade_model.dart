import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'grade_model.g.dart';

@HiveType(typeId: 8)
class Grade extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  String title;
  @HiveField(3)
  double score;
  @HiveField(4)
  double maxScore;
  @HiveField(5)
  double weight;
  @HiveField(6)
  final DateTime date;

  Grade({
    required this.id,
    required this.courseId,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_id': courseId,
    'title': title,
    'score': score,
    'max_score': maxScore,
    'weight': weight,
    'date': date.toIso8601String(),
  };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: JsonUtils.asString(json['id']),
    courseId: JsonUtils.asString(json['course_id']),
    title: JsonUtils.asString(json['title'], defaultValue: 'Untitled Grade'),
    score: JsonUtils.asDouble(json['score']),
    maxScore: JsonUtils.asDouble(json['max_score'], defaultValue: 100.0),
    weight: JsonUtils.asDouble(json['weight'], defaultValue: 1.0),
    date: JsonUtils.asDateTime(json['date']),
  );

  factory Grade.create({
    required String courseId,
    required String title,
    required double score,
    double maxScore = 100.0,
    double weight = 1.0,
    DateTime? date,
  }) {
    return Grade(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      score: score,
      maxScore: maxScore,
      weight: weight,
      date: date ?? DateTime.now(),
    );
  }
}
