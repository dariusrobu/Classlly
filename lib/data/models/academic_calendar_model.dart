import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'academic_calendar_model.g.dart';

@HiveType(typeId: 14)
enum AcademicPeriodType {
  @HiveField(0)
  teaching,
  @HiveField(1)
  exam,
  @HiveField(2)
  session,
  @HiveField(3)
  retake,
  @HiveField(4)
  holiday,
}

@HiveType(typeId: 15)
class AcademicPeriod extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime startDate;
  @HiveField(3)
  DateTime endDate;
  @HiveField(4)
  AcademicPeriodType type;

  AcademicPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'type': type.name,
  };

  factory AcademicPeriod.fromJson(Map<String, dynamic> json) => AcademicPeriod(
    id: JsonUtils.asString(json['id']),
    name: JsonUtils.asString(json['name'], defaultValue: 'Untitled Period'),
    startDate: JsonUtils.asDateTime(json['start_date']),
    endDate: JsonUtils.asDateTime(json['end_date']),
    type: AcademicPeriodType.values.firstWhere(
      (t) => t.name == JsonUtils.asString(json['type']),
      orElse: () => AcademicPeriodType.teaching,
    ),
  );

  factory AcademicPeriod.create({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required AcademicPeriodType type,
  }) {
    return AcademicPeriod(
      id: const Uuid().v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }
}

@HiveType(typeId: 16)
enum AcademicEventType {
  @HiveField(0)
  holiday,
  @HiveField(1)
  freeDay,
}

@HiveType(typeId: 17)
class AcademicEvent extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  AcademicEventType type;

  AcademicEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'type': type.name,
  };

  factory AcademicEvent.fromJson(Map<String, dynamic> json) => AcademicEvent(
    id: JsonUtils.asString(json['id']),
    name: JsonUtils.asString(json['name'], defaultValue: 'Untitled Event'),
    date: JsonUtils.asDateTime(json['date']),
    type: AcademicEventType.values.firstWhere(
      (t) => t.name == JsonUtils.asString(json['type']),
      orElse: () => AcademicEventType.holiday,
    ),
  );

  factory AcademicEvent.create({
    required String name,
    required DateTime date,
    required AcademicEventType type,
  }) {
    return AcademicEvent(
      id: const Uuid().v4(),
      name: name,
      date: date,
      type: type,
    );
  }
}
