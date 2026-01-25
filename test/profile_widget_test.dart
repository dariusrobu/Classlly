import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:mocktail/mocktail.dart';
import 'test_helper.dart';

void main() {
  late MockNotesRepository mockRepo;

  setUp(() {
    mockRepo = MockNotesRepository();
    when(() => mockRepo.getStudentProfile()).thenReturn(
      StudentProfile(
        name: 'Jane Doe',
        university: 'Test Uni',
        major: 'Architecture',
        year: '3',
        studentId: '67890',
      ),
    );
    when(() => mockRepo.getAllCourses()).thenReturn([]);
    when(() => mockRepo.getAllTasks()).thenReturn([]);
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen renders student name and major', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const ProfileScreen(),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
    });
  });
}
