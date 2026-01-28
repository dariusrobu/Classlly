import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/library/screens/dashboard_screen.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:mocktail/mocktail.dart';
import 'test_helper.dart';

void main() {
  late MockNotesRepository mockRepo;

  setUp(() {
    mockRepo = MockNotesRepository();

    // Mock behavior for methods not already overridden in MockNotesRepository
    when(() => mockRepo.getStudentProfile()).thenReturn(
      StudentProfile(
        name: 'Test Student',
        university: 'Test University',
        major: 'Computer Science',
        year: '2',
        studentId: '12345',
      ),
    );
    when(() => mockRepo.getAllCourses()).thenReturn([]);
    when(() => mockRepo.getAllTasks()).thenReturn([]);
  });

  group('Dashboard Widget Tests', () {
    testWidgets('QuickActionButton renders icon and label', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          QuickActionButton(
            icon: Icons.add,
            label: 'Action',
            color: Colors.blue,
            onTap: () => tapped = true,
          ),
          repository: mockRepo,
        ),
      );

      expect(find.text('Action'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(QuickActionButton));
      expect(tapped, true);
    });

    testWidgets('DashboardHeader renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(const DashboardHeader(), repository: mockRepo),
      );

      expect(find.textContaining('Welcome back'), findsOneWidget);
      expect(find.textContaining('Test Student'), findsOneWidget);
    });
  });
}
