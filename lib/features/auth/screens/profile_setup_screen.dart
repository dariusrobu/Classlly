import 'package:flutter/material.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/library_screen.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _studentIdController = TextEditingController();
  String _selectedYear = 'Year 1';
  bool _isLoading = false;
  List<dynamic> _availableTemplates = [];

  final List<String> _years = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Master',
    'PhD',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final provider = Provider.of<AcademicCalendarProvider>(context, listen: false);
    final templates = await provider.getAvailableTemplates();
    if (mounted) {
      setState(() {
        _availableTemplates = templates;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final fullName = user?.userMetadata?['full_name'] as String? ?? 'Student';

      final profile = StudentProfile(
        name: fullName,
        university: _universityController.text.trim(),
        major: _majorController.text.trim(),
        year: _selectedYear,
        studentId: _studentIdController.text.trim(),
      );

      final repo = NotesRepository();
      await repo.saveStudentProfile(profile);

      // Auto-load academic calendar if a template matches the selected university
      if (mounted) {
        final navigator = Navigator.of(context);
        final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
        final calendarProvider = Provider.of<AcademicCalendarProvider>(context, listen: false);

        final selectedUni = _universityController.text.trim();
        final template = _availableTemplates.firstWhere(
          (t) => t['universityName'] == selectedUni,
          orElse: () => null,
        );

        if (template != null) {
          await calendarProvider.loadTemplate(template);
        }

        libraryProvider.initSync();
        // Navigate to LibraryScreen, removing all previous routes (Auth, SignUp, Setup)
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipSetup() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final fullName = user?.userMetadata?['full_name'] as String? ?? 'Student';

      // Save minimal profile with just the name
      final profile = StudentProfile(name: fullName);
      final repo = NotesRepository();
      await repo.saveStudentProfile(profile);

      if (mounted) {
        Provider.of<LibraryProvider>(context, listen: false).initSync();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error skipping setup: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                'Setup Your Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tell us a bit about your academic background to personalize your experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return _availableTemplates.map((t) => t['universityName'] as String);
                            }
                            return _availableTemplates
                                .map((t) => t['universityName'] as String)
                                .where((String option) {
                              return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                            });
                          },
                          onSelected: (String selection) {
                            _universityController.text = selection;
                          },
                          fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                          ) {
                            // Sync the external controller with the autocomplete one
                            if (fieldTextEditingController.text != _universityController.text) {
                                fieldTextEditingController.text = _universityController.text;
                            }
                            // Listen to changes to update our controller
                            fieldTextEditingController.addListener(() {
                                _universityController.text = fieldTextEditingController.text;
                            });

                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: InputDecoration(
                                labelText: 'University / Institution',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.school_outlined),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'Required' : null,
                            );
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _majorController,
                      decoration: InputDecoration(
                        labelText: 'Major / Field of Study',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.book_outlined),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Current Year',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      items: _years.map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        labelText: 'Student ID (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Complete Setup',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _skipSetup,
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
