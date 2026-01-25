import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/repositories/supabase_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCloudStorageService extends Mock implements CloudStorageService {}
class MockNotesRepository extends Mock implements NotesRepository {}
class MockSupabaseRepository extends Mock implements SupabaseRepository {}

Widget wrapWidget(
  Widget child, {
  CloudStorageService? cloudService,
  NotesRepository? repository,
  SupabaseRepository? supabaseRepository,
}) {
  final repo = repository ?? MockNotesRepository();
  final supabaseRepo = supabaseRepository ?? MockSupabaseRepository();
  
  return MultiProvider(
    providers: [
      Provider<CloudStorageService>(create: (_) => cloudService ?? MockCloudStorageService()),
      ChangeNotifierProvider(create: (_) => CanvasProvider(
        repository: repo,
        remoteRepository: supabaseRepo,
      )),
      ChangeNotifierProvider(create: (_) => AudioProvider()),
      ChangeNotifierProvider(
        create: (context) => LibraryProvider(
          cloudService: context.read<CloudStorageService>(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => AcademicCalendarProvider(repository: repo)),
      ChangeNotifierProvider(create: (_) => ProfileProvider(repository: repo)),
      ChangeNotifierProvider(create: (_) => TaskProvider(repository: repo)),
      ChangeNotifierProvider(create: (_) => CourseProvider(repository: repo)),
      ChangeNotifierProvider(create: (_) => NotesProvider(repository: repo)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}