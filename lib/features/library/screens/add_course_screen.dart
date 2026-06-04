import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:intl/intl.dart';
import 'package:classlly/l10n/app_localizations.dart';

class AddCourseScreen extends StatefulWidget {
  final Course? course; // If provided, we are editing
  const AddCourseScreen({super.key, this.course});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info
  final _titleController = TextEditingController();
  final _creditsController = TextEditingController();
  String _semester = 'Semester 1';

  // Course (Lecture) Info
  final _profController = TextEditingController();
  final _courseRoomController = TextEditingController();
  String? _courseFrequency;
  String? _courseDay;
  TimeOfDay? _courseTime;

  // Seminar Info
  bool _hasSeminar = false;
  final _seminarProfController = TextEditingController();
  final _seminarRoomController = TextEditingController();
  String? _seminarFrequency;
  String? _seminarDay;
  TimeOfDay? _seminarTime;

  Color _selectedColor = Colors.blue;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  final List<String> _frequencies = [
    'Weekly',
    'Bi-Weekly (odd)',
    'Bi-Weekly (even)',
  ];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      final c = widget.course!;
      _titleController.text = c.title;
      _creditsController.text = c.credits.toString();
      _semester = c.semester.isNotEmpty ? c.semester : 'Semester 1';
      _selectedColor = Color(c.color);

      // Course
      _profController.text = c.professor;
      _courseRoomController.text = c.location;
      _courseFrequency = _frequencies.contains(c.courseFrequency)
          ? c.courseFrequency
          : null;
      _courseDay = _days.contains(c.courseDay) ? c.courseDay : null;
      _courseTime = _parseTime(c.courseTime);

      // Seminar
      _hasSeminar = c.seminarProfessor.isNotEmpty || 
                    c.seminarLocation.isNotEmpty || 
                    c.seminarFrequency.isNotEmpty || 
                    c.seminarDay.isNotEmpty || 
                    c.seminarTime.isNotEmpty;
      _seminarProfController.text = c.seminarProfessor;
      _seminarRoomController.text = c.seminarLocation;
      _seminarFrequency = _frequencies.contains(c.seminarFrequency)
          ? c.seminarFrequency
          : null;
      _seminarDay = _days.contains(c.seminarDay) ? c.seminarDay : null;
      _seminarTime = _parseTime(c.seminarTime);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      // Expecting "HH:mm AM/PM" or "HH:mm"
      final format = DateFormat.jm(); // 5:08 PM
      final dt = format.parse(timeStr);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CourseProvider>(context, listen: false);
      final credits = double.tryParse(_creditsController.text) ?? 0.0;
      final schedule = "${_courseDay ?? ''} ${_formatTime(_courseTime)}".trim();

      if (widget.course != null) {
        // Edit
        final updatedCourse = Course(
          id: widget.course!.id,
          title: _titleController.text,
          professor: _profController.text,
          schedule: schedule, // Legacy support
          location: _courseRoomController.text,
          color: _selectedColor.toARGB32(),
          semester: _semester,
          iconCodePoint: widget.course!.iconCodePoint,
          credits: credits,
          courseFrequency: _courseFrequency ?? '',
          courseDay: _courseDay ?? '',
          courseTime: _formatTime(_courseTime),
          seminarProfessor: _hasSeminar ? _seminarProfController.text : '',
          seminarLocation: _hasSeminar ? _seminarRoomController.text : '',
          seminarFrequency: _hasSeminar ? (_seminarFrequency ?? '') : '',
          seminarDay: _hasSeminar ? (_seminarDay ?? '') : '',
          seminarTime: _hasSeminar ? _formatTime(_seminarTime) : '',
        );
        await provider.saveCourse(updatedCourse);
      } else {
        // Create
        final newCourse = Course.create(
          title: _titleController.text,
          professor: _profController.text,
          schedule: schedule,
          location: _courseRoomController.text,
          color: _selectedColor,
          semester: _semester,
          credits: credits,
          courseFrequency: _courseFrequency ?? '',
          courseDay: _courseDay ?? '',
          courseTime: _formatTime(_courseTime),
          seminarProfessor: _hasSeminar ? _seminarProfController.text : '',
          seminarLocation: _hasSeminar ? _seminarRoomController.text : '',
          seminarFrequency: _hasSeminar ? (_seminarFrequency ?? '') : '',
          seminarDay: _hasSeminar ? (_seminarDay ?? '') : '',
          seminarTime: _hasSeminar ? _formatTime(_seminarTime) : '',
        );
        await provider.saveCourse(newCourse);
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 900),
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
              title: Text(
                widget.course != null
                    ? AppLocalizations.of(context)!.editCourse
                    : AppLocalizations.of(context)!.newCourse,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Basic Info ---
                    TextFormField(
                      controller: _titleController,
                      validator: (v) => v?.isEmpty == true
                          ? AppLocalizations.of(context)!.none
                          : null,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.courseTitle,
                        border: InputBorder.none,
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            AppLocalizations.of(context)!.credits,
                            _creditsController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            AppLocalizations.of(context)!.semester,
                            _semester,
                            [
                              '${AppLocalizations.of(context)!.semester} 1',
                              '${AppLocalizations.of(context)!.semester} 2',
                            ],
                            (val) => setState(() => _semester = val!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- Course (Lecture) Info ---
                    Text(
                      AppLocalizations.of(context)!.courseLectureDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      AppLocalizations.of(context)!.professor,
                      _profController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            AppLocalizations.of(context)!.room,
                            _courseRoomController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            AppLocalizations.of(context)!.frequency,
                            _courseFrequency,
                            [
                              AppLocalizations.of(context)!.weekly,
                              AppLocalizations.of(context)!.biWeeklyOdd,
                              AppLocalizations.of(context)!.biWeeklyEven,
                            ],
                            (val) => setState(() => _courseFrequency = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            AppLocalizations.of(context)!.day,
                            _courseDay,
                            [
                              AppLocalizations.of(context)!.monday,
                              AppLocalizations.of(context)!.tuesday,
                              AppLocalizations.of(context)!.wednesday,
                              AppLocalizations.of(context)!.thursday,
                              AppLocalizations.of(context)!.friday,
                              AppLocalizations.of(context)!.saturday,
                              AppLocalizations.of(context)!.sunday,
                            ],
                            (val) => setState(() => _courseDay = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePicker(
                            AppLocalizations.of(context)!.time,
                            _courseTime,
                            (val) => setState(() => _courseTime = val),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Theme(
                      data: Theme.of(context).copyWith(
                        listTileTheme: const ListTileThemeData(
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          AppLocalizations.of(context)!.seminarDetails,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        subtitle: Text(
                          'Optional', 
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                        value: _hasSeminar,
                        onChanged: (val) => setState(() => _hasSeminar = val),
                        activeThumbImage: null,
                        activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (_hasSeminar) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        AppLocalizations.of(context)!.seminarTeacher,
                        _seminarProfController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              AppLocalizations.of(context)!.room,
                              _seminarRoomController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              AppLocalizations.of(context)!.frequency,
                              _seminarFrequency,
                              [
                                AppLocalizations.of(context)!.weekly,
                                AppLocalizations.of(context)!.biWeeklyOdd,
                                AppLocalizations.of(context)!.biWeeklyEven,
                              ],
                              (val) => setState(() => _seminarFrequency = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              AppLocalizations.of(context)!.day,
                              _seminarDay,
                              [
                                AppLocalizations.of(context)!.monday,
                                AppLocalizations.of(context)!.tuesday,
                                AppLocalizations.of(context)!.wednesday,
                                AppLocalizations.of(context)!.thursday,
                                AppLocalizations.of(context)!.friday,
                                AppLocalizations.of(context)!.saturday,
                                AppLocalizations.of(context)!.sunday,
                              ],
                              (val) => setState(() => _seminarDay = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimePicker(
                              AppLocalizations.of(context)!.time,
                              _seminarTime,
                              (val) => setState(() => _seminarTime = val),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- Color ---
                    Text(
                      AppLocalizations.of(context)!.courseColor,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors
                          .map(
                            (c) => GestureDetector(
                              onTap: () => setState(() => _selectedColor = c),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedColor == c
                                        ? c
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _selectedColor == c
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.course != null
                              ? AppLocalizations.of(context)!.saveChanges
                              : AppLocalizations.of(context)!.createCourse,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 2,
            ), // Adjust vertical padding
          ),
          isExpanded: true,
          items: items
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? value,
    Function(TimeOfDay) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: value != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? _formatTime(value)
                        : AppLocalizations.of(context)!.select,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: value != null ? null : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
