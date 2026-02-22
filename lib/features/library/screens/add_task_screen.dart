import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/l10n/app_localizations.dart';

import 'package:provider/provider.dart';
import 'package:classlly/features/library/providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  final String? initialCourseId;
  final DateTime? initialDate;
  const AddTaskScreen({
    super.key,
    this.taskToEdit,
    this.initialCourseId,
    this.initialDate,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  Duration? _reminderOffset;
  int _priority = 1; // 0: Low, 1: Medium, 2: High
  String _taskType = 'assignment';
  final List<String> _categoryKeys = [
    'assignment',
    'exam',
    'reading',
    'project',
    'personal',
    'other',
  ];
  String? _selectedCourseId;
  final NotesRepository _repository = NotesRepository();
  List<Course> _courses = [];

  final Map<Duration?, String> _reminderOptions = {
    null: 'None',
    const Duration(hours: 1): '1 hour before',
    const Duration(hours: 2): '2 hours before',
    const Duration(days: 1): '1 day before',
    const Duration(days: 7): '1 week before',
  };

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descController.text = widget.taskToEdit!.description ?? '';
      _dueDate = widget.taskToEdit!.dueDate;
      _priority = widget.taskToEdit!.priority;
      
      // Handle category key migration/fallback
      final cat = widget.taskToEdit!.category?.toLowerCase();
      if (cat != null && _categoryKeys.contains(cat)) {
        _taskType = cat;
      } else if (widget.taskToEdit!.category != null) {
        // Fallback or attempt to match legacy localized strings
        _taskType = 'other';
      } else {
        _taskType = 'assignment';
      }
      
      _selectedCourseId = widget.taskToEdit!.courseId;

      if (widget.taskToEdit!.reminderTime != null && _dueDate != null) {
        final diff = _dueDate!.difference(widget.taskToEdit!.reminderTime!);
        // Find closest matching offset
        _reminderOffset = _reminderOptions.keys.firstWhere(
          (d) => d != null && (d.inMinutes - diff.inMinutes).abs() < 5,
          orElse: () => null,
        );
      }
    } else {
      _selectedCourseId = widget.initialCourseId;
      _dueDate = widget.initialDate;
    }
  }

  void _loadCourses() {
    setState(() {
      _courses = _repository.getAllCourses();
    });
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<TaskProvider>(context, listen: false);

        DateTime? reminderTime;
        if (_dueDate != null && _reminderOffset != null) {
          reminderTime = _dueDate!.subtract(_reminderOffset!);
        }

        if (widget.taskToEdit != null) {
          widget.taskToEdit!.title = _titleController.text;
          widget.taskToEdit!.description = _descController.text;
          widget.taskToEdit!.dueDate = _dueDate;
          widget.taskToEdit!.reminderTime = reminderTime;
          widget.taskToEdit!.priority = _priority;
          widget.taskToEdit!.courseId = _selectedCourseId;
          widget.taskToEdit!.category = _taskType;
          await provider.saveTask(widget.taskToEdit!);
        } else {
          final newTask = Task.create(
            title: _titleController.text,
            description: _descController.text,
            dueDate: _dueDate,
            reminderTime: reminderTime,
            priority: _priority,
            courseId: _selectedCourseId,
            category: _taskType,
          );
          await provider.saveTask(newTask);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving task: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.taskToEdit != null
                          ? AppLocalizations.of(context)!.editTask
                          : AppLocalizations.of(context)!.newTask,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  TextFormField(
                    controller: _titleController,
                    validator: (v) => v?.isEmpty == true
                        ? AppLocalizations.of(context)!.none
                        : null,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.taskName,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.descriptionOptional,
                      hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    AppLocalizations.of(context)!.priority,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(),

                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.schedule,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          AppLocalizations.of(context)!.dueDate,
                          _dueDate,
                          (d) => setState(() => _dueDate = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildReminderSelector()),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),

                  const SizedBox(height: 24),
                  if (_courses.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.courses,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCourseSelector(),
                  ],


                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.taskToEdit != null
                    ? AppLocalizations.of(context)!.saveChanges
                    : AppLocalizations.of(context)!.createTask,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

  Widget _buildPrioritySelector() {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.redAccent,
    ];
    final labels = [
      AppLocalizations.of(context)!.low,
      AppLocalizations.of(context)!.medium,
      AppLocalizations.of(context)!.high,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = _priority == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors[index].withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? colors[index] : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime? value,
    Function(DateTime) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          if (!mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );
          if (time != null) {
            onChanged(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          } else {
            onChanged(date);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  Icons.event,
                  size: 16,
                  color: value != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormat('MMM d, HH:mm').format(value)
                        : AppLocalizations.of(context)!.select,
                    style: TextStyle(
                      fontSize: 13,
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

  Widget _buildReminderSelector() {
    final reminderOptions = {
      null: AppLocalizations.of(context)!.none,
      const Duration(hours: 1): AppLocalizations.of(context)!.oneHourBefore,
      const Duration(hours: 2): AppLocalizations.of(context)!.twoHoursBefore,
      const Duration(days: 1): AppLocalizations.of(context)!.oneDayBefore,
      const Duration(days: 7): AppLocalizations.of(context)!.oneWeekBefore,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.reminder,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<Duration?>(
              value: _reminderOffset,
              isExpanded: true,
              icon: const Icon(
                Icons.notifications_active_outlined,
                size: 16,
                color: Colors.grey,
              ),
              items: reminderOptions.entries.map((e) {
                return DropdownMenuItem<Duration?>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _reminderOffset = val),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categoryKeys.map((key) {
        final isSelected = _taskType == key;
        final primaryColor = Theme.of(context).colorScheme.primary;
        return ChoiceChip(
          label: Text(_getCategoryLabel(key)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _taskType = key;
                if (_taskType == 'exam') {
                  _priority = 2;
                }
              });
            }
          },
          selectedColor: primaryColor.withValues(alpha: 0.15),
          backgroundColor: Theme.of(context).cardColor,
          labelStyle: TextStyle(
            color: isSelected ? primaryColor : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        );
      }).toList(),
    );
  }

  String _getCategoryLabel(String key) {
    if (!mounted) return key;
    switch (key) {
      case 'assignment':
        return AppLocalizations.of(context)!.assignment;
      case 'exam':
        return AppLocalizations.of(context)!.exam;
      case 'reading':
        return AppLocalizations.of(context)!.reading;
      case 'project':
        return AppLocalizations.of(context)!.project;
      case 'personal':
        return AppLocalizations.of(context)!.personal;
      case 'other':
        return AppLocalizations.of(context)!.other;
      default:
        return AppLocalizations.of(context)!.other;
    }
  }

  Widget _buildCourseSelector() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(AppLocalizations.of(context)!.none),
            selected: _selectedCourseId == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedCourseId = null);
            },
            selectedColor: primaryColor.withValues(alpha: 0.15),
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(
              color: _selectedCourseId == null ? primaryColor : Colors.grey,
              fontWeight: _selectedCourseId == null ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: _selectedCourseId == null ? primaryColor : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          const SizedBox(width: 8),
          ..._courses.map((c) {
            final isSelected = _selectedCourseId == c.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(c.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(c.title),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCourseId = c.id);
                },
                selectedColor: Color(c.color).withValues(alpha: 0.15),
                backgroundColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  color: isSelected ? Color(c.color) : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Color(c.color) : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            );
          }),
        ],
      ),
    );
  }
}
