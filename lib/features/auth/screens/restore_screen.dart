import 'package:classlly/core/services/supabase_cloud_service.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shown immediately after login while we restore data from Supabase.
///
/// Automatically navigates to [LibraryScreen] when restore completes.
class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  double _progress = 0.0;
  String _statusText = 'Connecting to cloud…';

  @override
  void initState() {
    super.initState();
    _runRestore();
  }

  Future<void> _runRestore() async {
    try {
      final cloudService = SupabaseCloudService();

      // Only restore if the user actually has cloud data.
      final hasData = await cloudService.hasCloudData();
      if (!hasData) {
        _finish();
        return;
      }

      await cloudService.restoreAll(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _statusText = step;
              _progress = progress;
            });
          }
        },
      );

      // Mark onboarding as completed so the user lands on the library.
      final repo = NotesRepository();
      final prefs = repo.getPreferences();
      prefs.hasCompletedOnboarding = true;
      await repo.savePreferences(prefs);
    } catch (e) {
      debugPrint('RestoreScreen error: $e');
      // On any error, proceed anyway — better to open the empty app than hang.
    }

    _finish();
  }

  void _finish() {
    if (!mounted) return;
    Provider.of<LibraryProvider>(context, listen: false).initSync();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_download_outlined,
                      size: 36, color: primary),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  'Restoring your data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / step label
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 6,
                    backgroundColor: primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _progress > 0
                      ? '${(_progress * 100).toInt()}%'
                      : 'Checking…',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
