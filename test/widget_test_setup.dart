import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';

class MockBox<T> extends Mock implements Box<T> {}

Future<void> setupWidgetTest() async {
  // Use a mock tail for Hive if possible, or just open real boxes in a temp dir
  // For widget tests, often we mock the Repository instead.
}

class MockNotesRepository extends Mock implements NotesRepository {
  @override
  StudentProfile getStudentProfile() {
    return StudentProfile(
      name: 'Test Student',
      university: 'Test Uni',
      major: 'Computer Science',
      year: '2',
      studentId: '12345',
    );
  }

  @override
  List<Course> getAllCourses() => [];

  List<Grade> getAllGrades() => [];

  @override
  List<Task> getAllTasks() => [];
}
