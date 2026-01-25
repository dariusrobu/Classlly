import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/core/constants/supabase_config.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/audio/providers/audio_provider.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/library/providers/notes_provider.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/features/auth/screens/onboarding_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() async {
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

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  // await notificationService.requestPermissions(); // Request when needed instead

  // Initialize Hive
  await Hive.initFlutter();
  await NotesRepository.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final app = MultiProvider(
    providers: [
      Provider<CloudStorageService>(create: (_) => SupabaseCloudService()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => CanvasProvider()),
      ChangeNotifierProvider(create: (_) => AudioProvider()),
      ChangeNotifierProvider(
        create: (context) => LibraryProvider(
          cloudService: context.read<CloudStorageService>(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => AcademicCalendarProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => TaskProvider()),
      ChangeNotifierProvider(create: (_) => CourseProvider()),
      ChangeNotifierProvider(create: (_) => NotesProvider()),
    ],
    child: const ClassllyApp(),
  );

  // Auto-init sync if user exists
  if (Supabase.instance.client.auth.currentUser != null) {
    // We need a context or a way to access the provider.
    // Since we just created the provider in the widget tree, we can't easily access it here.
    // Better: Handle it in LibraryScreen's initState or similar.
  }

  runApp(app);
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppTheme.primaryPurple;

  ThemeProvider() {
    _loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  void _loadPreferences() {
    try {
      final repository = NotesRepository();
      final prefs = repository.getPreferences();

      _themeMode = _parseThemeMode(prefs.themeMode);
      _accentColor = Color(prefs.accentColor);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _savePreferences();
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void _savePreferences() {
    try {
      final repository = NotesRepository();
      final prefs = repository.getPreferences();
      prefs.themeMode = _themeModeToString(_themeMode);
      prefs.accentColor = _accentColor.toARGB32();
      repository.savePreferences(prefs);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }
}

class ClassllyApp extends StatelessWidget {
  const ClassllyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final repo = NotesRepository();
    final prefs = repo.getPreferences();
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

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
      home: (isLoggedIn || prefs.hasCompletedOnboarding)
          ? const LibraryScreen()
          : const OnboardingScreen(),
    );
  }
}
