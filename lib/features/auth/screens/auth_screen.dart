import 'package:classlly/data/repositories/auth_repository.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/auth/screens/signup_screen.dart';
import 'package:classlly/features/auth/screens/profile_setup_screen.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authRepository = AuthRepository();
  late final CloudStorageService _cloudService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cloudService = Provider.of<CloudStorageService>(context, listen: false);
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // For email/password, we trust the user flow or check profile here if desired.
      // But standard flow: check profile.
      await _checkProfileAndNavigate();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSignUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SignUpScreen(),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithGoogle();
      await _checkProfileAndNavigate();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Google Sign In Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authRepository.signInWithApple();
      await _checkProfileAndNavigate();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Apple Sign In Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkProfileAndNavigate() async {
    if (!mounted) return;

    // Check if profile exists remotely
    final hasProfile = await _cloudService.hasProfile();

    if (!mounted) return;

    if (hasProfile) {
      _navigateToLibrary();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ProfileSetupScreen(),
      );
    }
  }

  void _navigateToLibrary() {
    if (mounted) {
      final repo = NotesRepository();
      final prefs = repo.getPreferences();
      prefs.hasCompletedOnboarding = true;
      repo.savePreferences(prefs);

      Provider.of<LibraryProvider>(context, listen: false).initSync();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LibraryScreen()),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Classlly',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _showSignUpDialog,
                          child: const Text('Don\'t have an account? Sign Up'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                          ), // Placeholder for Google Icon
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        if (kIsWeb ||
                            defaultTargetPlatform == TargetPlatform.iOS ||
                            defaultTargetPlatform == TargetPlatform.macOS) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _handleAppleSignIn,
                            icon: const Icon(Icons.apple, size: 24),
                            label: const Text('Continue with Apple'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () async {
                            final profileProvider =
                                Provider.of<ProfileProvider>(
                                  context,
                                  listen: false,
                                );
                            // Ensure demo profile data is populated (fixes missing data if any)
                            await profileProvider.createDemoProfile();

                            final repo = NotesRepository();
                            final prefs = repo.getPreferences();
                            prefs.hasCompletedOnboarding = true;
                            await repo.savePreferences(prefs);

                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LibraryScreen(),
                                ),
                              );
                            }
                          },
                          child: const Text('Continue as Guest (Offline)'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
