import 'package:flutter/material.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:classlly/l10n/app_localizations.dart';

class AcademicDetailsScreen extends StatefulWidget {
  const AcademicDetailsScreen({super.key});

  @override
  State<AcademicDetailsScreen> createState() => _AcademicDetailsScreenState();
}

class _AcademicDetailsScreenState extends State<AcademicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _universityController;
  late TextEditingController _majorController;
  late TextEditingController _yearController;
  late TextEditingController _studentIdController;
  final _repository = NotesRepository();
  late StudentProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = _repository.getStudentProfile();
    _universityController = TextEditingController(text: _profile.university);
    _majorController = TextEditingController(text: _profile.major);
    _yearController = TextEditingController(text: _profile.year);
    _studentIdController = TextEditingController(text: _profile.studentId);
  }

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _yearController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _profile.university = _universityController.text;
      _profile.major = _majorController.text;
      _profile.year = _yearController.text;
      _profile.studentId = _studentIdController.text;

      await _repository.saveStudentProfile(_profile);

      // Sync to Supabase
      // 3. Trigger Cloud Sync
      if (mounted) {
        // Sync profile using CloudStorageService
        final cloudService = Provider.of<CloudStorageService>(context, listen: false);
        await cloudService.syncProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.academicDetailsSaved),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.academicDetails),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(
                AppLocalizations.of(context)!.university,
                isDark,
              ),
              const SizedBox(height: 8),
              _buildTextField(_universityController, 'e.g. UBB Cluj', isDark),
              const SizedBox(height: 24),
              _buildFieldLabel(
                AppLocalizations.of(context)!.majorCourse,
                isDark,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                _majorController,
                'e.g. Computer Science',
                isDark,
              ),
              const SizedBox(height: 24),
              _buildFieldLabel(
                AppLocalizations.of(context)!.currentYear,
                isDark,
              ),
              const SizedBox(height: 8),
              _buildTextField(_yearController, 'e.g. Year 2', isDark),
              const SizedBox(height: 24),
              _buildFieldLabel(
                AppLocalizations.of(context)!.studentIdOptional,
                isDark,
              ),
              const SizedBox(height: 8),
              _buildTextField(_studentIdController, 'e.g. STUD-12345', isDark),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.updateAcademicInfo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (v) =>
          v == null || v.isEmpty ? AppLocalizations.of(context)!.none : null,
    );
  }
}
