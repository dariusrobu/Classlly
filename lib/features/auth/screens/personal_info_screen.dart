import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    // Also try to get from local profile to be consistent
    final repo = NotesRepository();
    final profile = repo.getStudentProfile();
    
    String initialName = profile.name ?? '';
    final supabaseName = user?.userMetadata?['full_name'] as String?;

    // If local name is the default 'Alex' but Supabase has a different name, use Supabase
    if ((initialName == 'Alex' || initialName.isEmpty) && 
        supabaseName != null && 
        supabaseName.isNotEmpty && 
        supabaseName != 'Alex') {
      initialName = supabaseName;
    } else if (initialName.isEmpty && supabaseName != null) {
      initialName = supabaseName;
    }
    
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        // 1. Update Supabase
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {'full_name': _nameController.text},
          ),
        );

        // 2. Update Local Profile
        final repo = NotesRepository();
        final profile = repo.getStudentProfile();
        profile.name = _nameController.text;
        await repo.saveStudentProfile(profile);

        // 3. Notify Listeners
        if (mounted) {
          Provider.of<LibraryProvider>(context, listen: false).refreshProfile();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personal Information'),
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
              _buildFieldLabel('Full Name', isDark),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'Enter your full name', isDark),
              const SizedBox(height: 24),
              _buildFieldLabel('Email Address', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                _emailController,
                'Email',
                isDark,
                enabled: false,
              ), // Email usually not editable directly
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
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
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
        filled: true,
        fillColor:
            isDark
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
      validator: (v) => v == null || v.isEmpty ? 'Field cannot be empty' : null,
    );
  }
}
