import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/task_model.dart';

import 'package:classlly/data/models/student_profile_model.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

class CourseFake extends Fake implements Course {}

class TaskFake extends Fake implements Task {}

class AttendanceFake extends Fake implements Attendance {}

class GradeFake extends Fake implements Grade {}

class StudentProfileFake extends Fake implements StudentProfile {}

void main() {
  setUpAll(() {
    registerFallbackValue(CourseFake());
    registerFallbackValue(TaskFake());
    registerFallbackValue(AttendanceFake());
    registerFallbackValue(GradeFake());
    registerFallbackValue(StudentProfileFake());
  });

  late ProfileProvider profileProvider;
  late MockNotesRepository mockRepository;

  setUp(() {
    mockRepository = MockNotesRepository();
    // Stub saveStudentProfile here as it is called during initialization or usage
    when(() => mockRepository.saveStudentProfile(any())).thenAnswer((_) async {});
    profileProvider = ProfileProvider(repository: mockRepository);
  });

  group('ProfileProvider', () {
    test('createDemoProfile populates repository with data', () async {
      when(() => mockRepository.getAllCourses()).thenReturn([]);
      when(() => mockRepository.getAttendanceForCourse(any())).thenReturn([]);
      when(() => mockRepository.getGradesForCourse(any())).thenReturn([]);
      when(() => mockRepository.saveCourse(any())).thenAnswer((_) async {});
      when(() => mockRepository.saveAttendance(any())).thenAnswer((_) async {});
      when(() => mockRepository.saveGrade(any())).thenAnswer((_) async {});
      when(() => mockRepository.saveTask(any())).thenAnswer((_) async {});

      await profileProvider.createDemoProfile();

      // Verify that courses were saved (demo creates 10 courses)
      verify(() => mockRepository.saveCourse(any())).called(10);

      // Verify attendance records were saved (10 courses * 10 records = 100)
      verify(() => mockRepository.saveAttendance(any())).called(100);

      // Verify grades were saved (10 courses * 5 grades = 50)
      verify(() => mockRepository.saveGrade(any())).called(50);

      // Verify tasks were saved (10 courses * 4 tasks + 10 personal = 50)
      verify(() => mockRepository.saveTask(any())).called(50);
    });
  });
}
