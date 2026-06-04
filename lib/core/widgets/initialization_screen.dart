import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/constants/supabase_config.dart';
import 'package:classlly/core/services/notification_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/features/auth/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/core/theme/theme_provider.dart';
import 'package:classlly/core/services/sync_manager.dart';

/// Handles the early initialization of Hive, Supabase, and Notifications
/// after the app has already booted into the Flutter engine.
/// Moving these out of main() prevents the OS from killing the app
/// if any of these take too long during cold start on physical devices.
class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String _message = 'Starting Classlly...';
  bool _hasError = false;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!kIsWeb &&
          (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
        await NotificationService().init();
      }

      setState(() => _message = 'Loading local storage...');
      await Hive.initFlutter();
      await NotesRepository.init();

      if (mounted) {
        Provider.of<ThemeProvider>(context, listen: false).loadPreferences();
      }

      setState(() => _message = 'Connecting to cloud...');
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      setState(() => _message = 'Initializing sync services...');
      await SyncManager().init();

      _finish();
    } catch (e, stack) {
      debugPrint('CRITICAL Initialization Error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetail = e.toString();
        });
      }
    }
  }

  void _finish() {
    if (!mounted) return;

    final repo = NotesRepository();
    final prefs = repo.getPreferences();
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    // Trigger initial sync if logged in
    if (isLoggedIn) {
      Provider.of<LibraryProvider>(context, listen: false).initSync();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => (isLoggedIn || prefs.hasCompletedOnboarding)
            ? const LibraryScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorDetail ?? 'Unknown error occurred during startup',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorDetail = null;
                      _message = 'Retrying startup...';
                    });
                    _initialize();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            Text(
              _message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
