import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/core/theme/theme_provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/core/services/cloud_provider.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:classlly/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:classlly/core/widgets/initialization_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CRITICAL ERROR: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: const Color(0xFF121212),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              details.exception.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => main(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<CloudStorageService>(
          create: (_) => CloudProviderManager.getService(
            CloudProviderManager.getCurrentProvider(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              LibraryProvider(cloudService: context.read<CloudStorageService>()),
        ),
        ChangeNotifierProvider(create: (_) => AcademicCalendarProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const ClassllyApp(),
    ),
  );
}



class ClassllyApp extends StatelessWidget {
  const ClassllyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Classlly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeProvider.accentColor),
      darkTheme: AppTheme.darkTheme(themeProvider.accentColor),
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'), // English (UK) - Starts on Monday
        Locale('ro', 'RO'), // Romanian - Starts on Monday
      ],
      locale: const Locale('en', 'GB'),
      home: const InitializationScreen(),
    );
  }
}

