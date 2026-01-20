import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
