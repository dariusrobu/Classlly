import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:classlly/main.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/constants/supabase_config.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
// ThemeProvider import
import 'package:classlly/core/theme/theme_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Generate App Store Screenshots', (WidgetTester tester) async {
    // 1. Initialize & Clear Data
    await Hive.initFlutter();
    await NotesRepository.init();
    await NotesRepository().clearAllData();

    final repo = NotesRepository();

    // ---------------------------------------------------------
    // SETUP: Init Supabase & Providers
    // ---------------------------------------------------------
    
    // Initialize Supabase (Safe to call multiple times? verify)
    // Supabase.initialize checks if already initialized usually.
    try {
      await Supabase.initialize(
        url: 'https://kqwbduqdzgeevtcifnqx.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxd2JkdXFkemdlZXZ0Y2lmbnF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk3NDksImV4cCI6MjA4Mzk5NTc0OX0.8EpXvPIoRrtKBwLM1ad0qd3I_85L-JVJ5HVfy4k6jsg',
      );
    } catch (_) {
      // Already initialized
    }
    
    // Create the app widget with all Providers from main.dart
    final app = MultiProvider(
      providers: [
        Provider<CloudStorageService>(create: (_) => SupabaseCloudService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(
          create: (context) => LibraryProvider(cloudService: context.read<CloudStorageService>()),
        ),
        ChangeNotifierProvider(create: (_) => AcademicCalendarProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const ClassllyApp(),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // SCREENSHOT: Onboarding
    // ---------------------------------------------------------
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_onboarding');
    
    // Complete Onboarding
    final skipButton = find.text('Skip');
    if (skipButton.evaluate().isNotEmpty) {
      await tester.tap(skipButton);
      await tester.pumpAndSettle();
    } else {
        final getStarted = find.text('Get Started');
         if (getStarted.evaluate().isNotEmpty) {
            await tester.tap(getStarted);
            await tester.pumpAndSettle();
         }
    }
    
    // ---------------------------------------------------------
    // SEED DATA DIRECTLY
    // ---------------------------------------------------------
    
    // Courses
    final mathId = const Uuid().v4();
    final physId = const Uuid().v4();
    
    final mathCourse = Course.create(
      title: 'Mathematics',
      color: Colors.blueAccent,
      icon: Icons.calculate,
      credits: 3,
      schedule: 'Mon 10:00 AM',
      location: 'Hall A',
      professor: 'Dr. Smith'
    ); // Our create factory might differ, using standard model if needed or specific fields.
    // Actually the `create` factory I saw handles ID gen.
    // Let's rely on repo.saveCourse
    
    // Since I can't easily use the `create` factory output without saving, let's just make one and save it.
    // The model uses HiveObject, so we should be careful.
    
    // Let's use the UI flow for Courses just to be safe on model logic, 
    // OR create simpler objects if I know the structure. 
    // I know the structure from previous `view_file`.
    // I will use `Course.create` then update ID? no, create makes ID.
    // I need to capture the ID to link tasks/grades.
    
    final c1 = Course.create(
        title: 'Advanced Mathematics',
        color: Colors.indigo,
        icon: Icons.functions,
        credits: 5.0,
        professor: 'Dr. A. Turing',
        location: 'Room 304'
    );
    await repo.saveCourse(c1);
    
    final c2 = Course.create(
        title: 'Physics',
        color: Colors.orange,
        icon: Icons.lightbulb,
        credits: 4.0,
        professor: 'Dr. Einstein',
        location: 'Lab 1'
    );
    await repo.saveCourse(c2);
    
    // Tasks
    final t1 = Task.create(
        title: 'Complete Algebra Assignment',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        courseId: c1.id,
        priority: 2, // High
        category: 'Homework'
    );
    await repo.saveTask(t1);
    
    final t2 = Task.create(
        title: 'Read Chapter 4: Relativty',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        courseId: c2.id,
        priority: 1, // Med
        category: 'Reading'
    );
    await repo.saveTask(t2);
    
    // Grades
    final g1 = Grade.create(
        courseId: c1.id,
        title: 'Midterm Exam',
        score: 95.0,
        maxScore: 100.0,
        weight: 30.0,
        date: DateTime.now().subtract(const Duration(days: 10))
    );
    await repo.saveGrade(g1);
    
    final g2 = Grade.create(
        courseId: c2.id,
        title: 'Lab Report 1',
        score: 88.0,
        maxScore: 100.0,
        weight: 15.0,
        date: DateTime.now().subtract(const Duration(days: 5))
    );
    await repo.saveGrade(g2);
    
    // Calendar Events (Holidays)
    final event1 = AcademicEvent.create(
        name: 'Winter Break',
        date: DateTime.now().add(const Duration(days: 20)),
        type: AcademicEventType.holiday,
    );
    await repo.saveEvent(event1);

    // Exam as Task
    final examTask = Task.create(
      title: 'Math Final Exam',
      dueDate: DateTime.now().add(const Duration(days: 18)),
      courseId: c1.id,
      priority: 2,
      category: 'Exam'
    );
    await repo.saveTask(examTask);
    
    // Refresh UI
    // Tapping around or pumping might trigger data reload if streams are listening.
    // LibraryScreen usually listens to provider.
    // We might need to restart app or just force refresh?
    // Providers should update if they listen to Hive box? 
    // They usually `notifyListeners` on changes if they are reactive. 
    // Or we need to call `loadData`.
    
    // Let's force a rebuild by re-pumping widget or navigating.
    // We are on Dashboard (LibraryScreen) which is the home.
    // Re-pump should handle it if using ValueListenableBuilder.
    await tester.pumpAndSettle();

    // ---------------------------------------------------------
    // SCREENSHOT: Dashboard
    // ---------------------------------------------------------
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_dashboard');
    
    // ---------------------------------------------------------
    // SCREENSHOT: Tasks
    // ---------------------------------------------------------
    // Find "Tasks" tab/sidebar item.
    // LibraryScreen usually has a Sidebar or BottomNav.
    // Let's assume text "Tasks" is clickable.
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_tasks_view');
    
    // ---------------------------------------------------------
    // SCREENSHOT: Calendar
    // ---------------------------------------------------------
    await tester.tap(find.text('Calendar')); // or 'Academic Calendar'
    await tester.pumpAndSettle();
    
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_calendar_view');
    
    // ---------------------------------------------------------
    // SCREENSHOT: Note Canvas
    // ---------------------------------------------------------
    // Go back to Courses/Dashboard
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    
    // Tap on Math Course
    await tester.tap(find.text('Advanced Mathematics'));
    await tester.pumpAndSettle();
    
    // Create Note
    final addNoteFinder = find.text('Add Note');
    if (addNoteFinder.evaluate().isNotEmpty) {
        await tester.tap(addNoteFinder);
    } else {
         await tester.tap(find.byIcon(Icons.add));
    }
    await tester.pumpAndSettle();
    
    if (find.text('Note Title').evaluate().isNotEmpty) {
        await tester.enterText(find.widgetWithText(TextField, 'Note Title'), 'Derivatives');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();
    }
    
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_note_canvas');
    
    // ---------------------------------------------------------
    // SCREENSHOT: Course Stats / Grades
    // ---------------------------------------------------------
    // Back to Course Detail
    final backButton = find.byTooltip('Back'); // Material back button
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
    
    // In Course Detail, Tap "Performance" or "Grades" tab/button if exists.
    // Or maybe it's on the main detail page.
    // Checking strings... "performanceOverview": "Performance Overview"
    // Does Course Detail show it?
    // Let's assume there is a way to see stats.
    // Maybe "Grades" tab in Course Detail?
    
    // If we can't find it easily, we might skip or try to find "Grades".
    // "gradeHistory": "Grade History" from arb.
    
    // Let's try to scroll down if needed.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06_course_detail_stats');
  });
}
