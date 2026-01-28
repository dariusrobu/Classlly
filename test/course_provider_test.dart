import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

class CourseFake extends Fake implements Course {}

void main() {
  setUpAll(() {
    registerFallbackValue(CourseFake());
  });

  late CourseProvider courseProvider;
  late MockNotesRepository mockRepository;

  setUp(() {
    mockRepository = MockNotesRepository();
    courseProvider = CourseProvider(repository: mockRepository);
  });

  group('CourseProvider - recalculateStats', () {
    test('calculates correct average grade and attendance rate', () async {
      // Setup
      final course = Course.create(title: 'Test Course');
      final grades = [
        Grade.create(courseId: course.id, title: 'G1', score: 80, weight: 0.5),
        Grade.create(courseId: course.id, title: 'G2', score: 90, weight: 0.5),
      ];
      final attendance = [
        Attendance.create(
          courseId: course.id,
          status: AttendanceStatus.present,
        ),
        Attendance.create(courseId: course.id, status: AttendanceStatus.absent),
      ];

      when(() => mockRepository.getAllCourses()).thenReturn([course]);
      when(
        () => mockRepository.getGradesForCourse(course.id),
      ).thenReturn(grades);
      when(
        () => mockRepository.getAttendanceForCourse(course.id),
      ).thenReturn(attendance);
      when(() => mockRepository.saveCourse(any())).thenAnswer((_) async {});

      // Act
      await courseProvider.recalculateStats();

      // Assert
      // (80*0.5 + 90*0.5) / 1.0 = 85.0
      expect(course.cachedAverageGrade, 85.0);
      // 1 present out of 2 = 50.0%
      expect(course.cachedAttendanceRate, 50.0);

      verify(() => mockRepository.saveCourse(course)).called(1);
    });

    test('handles empty grades and attendance', () async {
      final course = Course.create(title: 'Empty Course');

      when(() => mockRepository.getAllCourses()).thenReturn([course]);
      when(() => mockRepository.getGradesForCourse(course.id)).thenReturn([]);
      when(
        () => mockRepository.getAttendanceForCourse(course.id),
      ).thenReturn([]);
      when(() => mockRepository.saveCourse(any())).thenAnswer((_) async {});

      await courseProvider.recalculateStats();

      expect(course.cachedAverageGrade, 0.0);
      expect(course.cachedAttendanceRate, 0.0);
    });
  });
}
