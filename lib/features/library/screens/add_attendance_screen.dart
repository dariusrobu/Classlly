import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/course_provider.dart';

class AddAttendanceScreen extends StatefulWidget {
  final Attendance? attendance;
  final String? initialCourseId;

  const AddAttendanceScreen({super.key, this.attendance, this.initialCourseId});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  AttendanceStatus _status = AttendanceStatus.present;
  String? _selectedCourseId;
  final NotesRepository _repository = NotesRepository();
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (widget.attendance != null) {
      _date = widget.attendance!.date;
      _status = widget.attendance!.status;
      _selectedCourseId = widget.attendance!.courseId;
    } else {
      _selectedCourseId = widget.initialCourseId;
    }
  }

  void _loadCourses() {
    setState(() {
      _courses = _repository.getAllCourses();
    });
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourseId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a course')));
        return;
      }

      final provider = Provider.of<CourseProvider>(context, listen: false);
      if (widget.attendance != null) {
        widget.attendance!.date = _date;
        widget.attendance!.status = _status;
        // courseId usually doesn't change on edit, but we could update it if needed
        await provider.saveAttendance(widget.attendance!);
      } else {
        final newAttendance = Attendance.create(
          courseId: _selectedCourseId!,
          date: _date,
          status: _status,
        );
        await provider.saveAttendance(newAttendance);
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                widget.attendance != null
                    ? 'Edit Attendance'
                    : 'Mark Attendance',
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
                    const Text(
                      'Course',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCourseSelector(),
                    const SizedBox(height: 24),
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 24),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusSelector(),
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
                          widget.attendance != null
                              ? 'Save Changes'
                              : 'Mark Present',
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

  Widget _buildCourseSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedCourseId,
          hint: const Text('Select Course', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          validator: (v) => v == null ? 'Required' : null,
          items: _courses
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(c.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.title,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedCourseId = val),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) setState(() => _date = d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM d, y').format(_date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      children: AttendanceStatus.values.map((status) {
        final isSelected = _status == status;
        Color color;
        IconData icon;
        switch (status) {
          case AttendanceStatus.present:
            color = Colors.green;
            icon = Icons.check_circle;
            break;
          case AttendanceStatus.absent:
            color = Colors.red;
            icon = Icons.cancel;
            break;
          case AttendanceStatus.late:
            color = Colors.amber;
            icon = Icons.access_time_filled;
            break;
          case AttendanceStatus.excused:
            color = Colors.blue;
            icon = Icons.info;
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () => setState(() => _status = status),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected) Icon(Icons.check, color: color, size: 16),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
