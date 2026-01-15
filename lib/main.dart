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
import 'package:classlly/features/auth/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => CanvasProvider()),
      ChangeNotifierProvider(create: (_) => AudioProvider()),
      ChangeNotifierProvider(create: (_) => LibraryProvider()),
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
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class ClassllyApp extends StatelessWidget {
  const ClassllyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Classlly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Supabase.instance.client.auth.currentUser != null
          ? const LibraryScreen()
          : const AuthScreen(),
    );
  }
}
