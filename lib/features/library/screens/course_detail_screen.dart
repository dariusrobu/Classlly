import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:classlly/core/widgets/glass_card.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/library/screens/add_attendance_screen.dart';
import 'package:classlly/features/library/providers/course_provider.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';
import 'package:classlly/features/library/screens/add_course_screen.dart';
import 'package:classlly/l10n/app_localizations.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Course _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNote(BuildContext context) {
    final note = Note.create(title: AppLocalizations.of(context)!.noteTitle);
    note.tags = [_course.title, _course.id]; // Link to course
    Provider.of<CanvasProvider>(context, listen: false).setNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CanvasScreen()),
    );
  }

  void _addTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskScreen(initialCourseId: _course.id),
    );
  }

  void _addGrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddGradeDialog(courseId: _course.id),
    );
  }

  void _addAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAttendanceScreen(initialCourseId: _course.id),
    );
  }

  void _showGradeHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ValueListenableBuilder(
        valueListenable: Hive.box<Grade>(
          NotesRepository.gradeBoxName,
        ).listenable(),
        builder: (context, Box<Grade> box, _) {
          final grades =
              box.values.where((g) => g.courseId == _course.id).toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.gradeHistory,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: grades.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noGradesRecorded,
                        ),
                      )
                    : ListView.builder(
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          final grade = grades[index];
                          return ListTile(
                            title: Text(
                              grade.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!.gradeMetadata(
                                DateFormat.yMMMd().format(grade.date),
                                (grade.weight * 100).toInt(),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${grade.score}/${grade.maxScore}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AddGradeDialog(
                                          courseId: _course.id,
                                          grade: grade,
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.deleteGrade,
                                          ),
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.deleteGradeConfirm,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.cancel,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.delete,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true &&
                                          context.mounted) {
                                        final courseProvider =
                                            Provider.of<CourseProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await courseProvider.deleteGrade(
                                          grade.id,
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttendanceHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ValueListenableBuilder(
        valueListenable: Hive.box<Attendance>(
          NotesRepository.attendanceBoxName,
        ).listenable(),
        builder: (context, Box<Attendance> box, _) {
          final records =
              box.values.where((r) => r.courseId == _course.id).toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.attendanceHistory,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noAttendanceRecords,
                        ),
                      )
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isPresent =
                              record.status == AttendanceStatus.present;
                          final isExcused =
                              record.status == AttendanceStatus.excused;
                          final color = isPresent
                              ? Colors.green
                              : (isExcused ? Colors.orange : Colors.red);
                          return ListTile(
                            leading: Icon(
                              isPresent
                                  ? Icons.check_circle
                                  : (isExcused ? Icons.info : Icons.cancel),
                              color: color,
                            ),
                            title: Text(DateFormat.yMMMd().format(record.date)),
                            subtitle: Text(DateFormat.jm().format(record.date)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            AddAttendanceScreen(
                                              initialCourseId: _course.id,
                                              attendance: record,
                                            ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.deleteRecord,
                                          ),
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.deleteAttendanceConfirm,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.cancel,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.delete,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true &&
                                          context.mounted) {
                                        final courseProvider =
                                            Provider.of<CourseProvider>(
                                              context,
                                              listen: false,
                                            );
                                        await courseProvider.deleteAttendance(
                                          record.id,
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCourseScreen(course: _course)),
    );

    if (result == true && mounted) {
      final repo = NotesRepository();
      final updated = repo.getCourse(_course.id);
      if (updated != null) {
        setState(() {
          _course = updated;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCourse),
        content: Text(AppLocalizations.of(context)!.deleteCourseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<CourseProvider>(
        context,
        listen: false,
      ).deleteCourse(_course.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFF1C1C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(
                                context,
                                isDark,
                                primaryColor,
                                isMobile,
                              ),
                              const SizedBox(height: 24),
                              _buildQuickActions(context, isDark, primaryColor),
                              const SizedBox(height: 24),
                              TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                dividerColor: Colors.transparent,
                                labelColor: primaryColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: primaryColor,
                                tabs: [
                                  Tab(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.overview,
                                  ),
                                  Tab(
                                    text: AppLocalizations.of(context)!.notes,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(context, isDark, primaryColor),
                      _buildNotesTab(context, isDark, primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    if (isMobile) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceCharts(isDark, primaryColor, isMobile),
            const SizedBox(height: 24),
            _buildRecentGradesCard(isDark, primaryColor),
            const SizedBox(height: 24),
            _buildAttendanceRecords(isDark, primaryColor),
            const SizedBox(height: 32),
            _buildCourseInfoCard(isDark, primaryColor),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.recentActivity,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentNotesList(isDark, primaryColor, limit: 3),
            const SizedBox(height: 32),
            _buildTasksCard(isDark, primaryColor),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceCharts(isDark, primaryColor, isMobile),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRecentGradesCard(isDark, primaryColor)),
              const SizedBox(width: 24),
              Expanded(child: _buildAttendanceRecords(isDark, primaryColor)),
            ],
          ),
          const SizedBox(height: 32),
          _buildCourseInfoCard(isDark, primaryColor),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.recentActivity,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentNotesList(isDark, primaryColor, limit: 3),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(child: _buildTasksCard(isDark, primaryColor)),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, bool isDark, Color primaryColor) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
      child: _buildRecentNotesList(isDark, primaryColor, limit: 100),
    );
  }

  /// Inline Recent Grades card
  Widget _buildRecentGradesCard(bool isDark, Color primaryColor) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Grades',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showGradeHistory(context),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: Hive.box<Grade>(
              NotesRepository.gradeBoxName,
            ).listenable(),
            builder: (context, Box<Grade> gradeBox, _) {
              final courseGrades =
                  gradeBox.values
                      .where((g) => g.courseId == _course.id)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
              final recent = courseGrades.take(3).toList();

              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No grades yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: recent.map((grade) {
                  final pct = (grade.score / grade.maxScore * 100);
                  String letterGrade = 'F';
                  Color gradeColor = Colors.red;
                  if (pct >= 90) {
                    letterGrade = 'A';
                    gradeColor = Colors.green;
                  } else if (pct >= 80) {
                    letterGrade = 'B';
                    gradeColor = Colors.blue;
                  } else if (pct >= 70) {
                    letterGrade = 'C';
                    gradeColor = Colors.orange;
                  } else if (pct >= 60) {
                    letterGrade = 'D';
                    gradeColor = Colors.deepOrange;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: gradeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              letterGrade,
                              style: TextStyle(
                                color: gradeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                grade.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat.MMMd().format(grade.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: gradeColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Attendance records timeline
  Widget _buildAttendanceRecords(bool isDark, Color primaryColor) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Records',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showAttendanceHistory(context),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: Hive.box<Attendance>(
              NotesRepository.attendanceBoxName,
            ).listenable(),
            builder: (context, Box<Attendance> attBox, _) {
              final courseAtt =
                  attBox.values.where((a) => a.courseId == _course.id).toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
              final recent = courseAtt.take(5).toList();

              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No attendance records yet',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: recent.map((att) {
                  final isPresent =
                      att.status == AttendanceStatus.present ||
                      att.status == AttendanceStatus.excused;
                  final statusColor = isPresent ? Colors.green : Colors.red;
                  final statusLabel = att.status == AttendanceStatus.present
                      ? 'Present'
                      : att.status == AttendanceStatus.excused
                      ? 'Excused'
                      : 'Absent';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, MMM d').format(att.date),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _actionButton(
            context,
            AppLocalizations.of(context)!.addNote,
            Icons.edit_note,
            () => _addNote(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            AppLocalizations.of(context)!.addTask,
            Icons.check_circle_outline,
            () => _addTask(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            AppLocalizations.of(context)!.addGrade,
            Icons.grade_outlined,
            () => _addGrade(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            AppLocalizations.of(context)!.markAttendance,
            Icons.person_add_alt_1_outlined,
            () => _addAttendance(context),
            isDark,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isMobile,
  ) {
    return GlassCard(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.backToCourses,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: primaryColor),
                    onSelected: (value) {
                      if (value == 'edit') _handleEdit();
                      if (value == 'delete') _handleDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.of(context)!.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _course.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: isDark ? const Color(0xFFAD8DCE) : Colors.grey[800],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _course.professor.isNotEmpty
                        ? _course.professor
                        : AppLocalizations.of(context)!.noInstructor,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFAD8DCE)
                          : Colors.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_course.semester.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _course.semester.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Course Syllabus button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Course Syllabus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Fetch grade and attendance for header stats
          ValueListenableBuilder(
            valueListenable: Hive.box<Grade>(
              NotesRepository.gradeBoxName,
            ).listenable(),
            builder: (context, Box<Grade> gradeBox, _) {
              final courseGrades =
                  gradeBox.values
                      .where((g) => g.courseId == _course.id)
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

              double avg = 0;
              int gradeTrend = 0;

              if (courseGrades.isNotEmpty) {
                // Calculate current average
                double totalWeightedScore = 0;
                double totalWeight = 0;
                for (var g in courseGrades) {
                  totalWeightedScore +=
                      ((g.score / g.maxScore) * 100) * g.weight;
                  totalWeight += g.weight;
                }
                avg = totalWeight > 0 ? totalWeightedScore / totalWeight : 0;

                // Calculate previous average (excluding last)
                if (courseGrades.length > 1) {
                  double prevTotalWeightedScore = 0;
                  double prevTotalWeight = 0;
                  for (int i = 0; i < courseGrades.length - 1; i++) {
                    final g = courseGrades[i];
                    prevTotalWeightedScore +=
                        ((g.score / g.maxScore) * 100) * g.weight;
                    prevTotalWeight += g.weight;
                  }
                  double prevAvg = prevTotalWeight > 0
                      ? prevTotalWeightedScore / prevTotalWeight
                      : 0;
                  gradeTrend = avg > prevAvg ? 1 : (avg < prevAvg ? -1 : 0);
                }
              }

              return ValueListenableBuilder(
                valueListenable: Hive.box<Attendance>(
                  NotesRepository.attendanceBoxName,
                ).listenable(),
                builder: (context, Box<Attendance> attBox, _) {
                  final courseAtt =
                      attBox.values
                          .where((a) => a.courseId == _course.id)
                          .toList()
                        ..sort((a, b) => a.date.compareTo(b.date));

                  double attendance = 0;
                  int attTrend = 0;

                  if (courseAtt.isNotEmpty) {
                    final presentCount = courseAtt
                        .where(
                          (r) =>
                              r.status == AttendanceStatus.present ||
                              r.status == AttendanceStatus.excused,
                        )
                        .length;
                    attendance = (presentCount / courseAtt.length) * 100;

                    if (courseAtt.length > 1) {
                      final prevPresentCount = courseAtt
                          .take(courseAtt.length - 1)
                          .where(
                            (r) =>
                                r.status == AttendanceStatus.present ||
                                r.status == AttendanceStatus.excused,
                          )
                          .length;
                      double prevAttendance =
                          (prevPresentCount / (courseAtt.length - 1)) * 100;
                      attTrend = attendance > prevAttendance
                          ? 1
                          : (attendance < prevAttendance ? -1 : 0);
                    }
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.start,
                    children: [
                      _headerStatItem(
                        AppLocalizations.of(context)!.currentGrade,
                        courseGrades.isEmpty
                            ? 'N/A'
                            : '${NumberFormat('0.##').format(avg)}%',
                        gradeTrend,
                        isDark,
                        isMobile,
                      ),
                      _headerStatItem(
                        AppLocalizations.of(context)!.attendance.toUpperCase(),
                        courseAtt.isEmpty ? 'N/A' : '${attendance.toInt()}%',
                        attTrend,
                        isDark,
                        isMobile,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(
    String label,
    String value,
    int trendDirection,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      constraints: BoxConstraints(minWidth: isMobile ? 120 : 140),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFAD8DCE),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (trendDirection != 0)
                Icon(
                  trendDirection > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendDirection > 0
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCharts(bool isDark, Color primaryColor, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 800 ? 2 : 1;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.8 : 2.4, // Provide more vertical space on mobile
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildTrendChart(isDark, primaryColor),
            _buildAttendanceChart(isDark, primaryColor),
          ],
        );
      },
    );
  }

  Widget _buildTrendChart(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Grade>(
        NotesRepository.gradeBoxName,
      ).listenable(),
      builder: (context, Box<Grade> box, _) {
        final courseGrades =
            box.values.where((g) => g.courseId == _course.id).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

        List<FlSpot> spots = [];
        if (courseGrades.isNotEmpty) {
          spots = courseGrades.asMap().entries.map((e) {
            final pct = (e.value.score / e.value.maxScore) * 5; // Scale to 0-5
            return FlSpot(e.key.toDouble(), pct);
          }).toList();
        } else {
          spots = const [FlSpot(0, 0), FlSpot(1, 0)];
        }

        return GlassCard(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grade Trend',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showGradeHistory(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 5.5, // Slightly higher to avoid clipping
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceChart(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Attendance>(
        NotesRepository.attendanceBoxName,
      ).listenable(),
      builder: (context, Box<Attendance> box, _) {
        final records =
            box.values.where((r) => r.courseId == _course.id).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

        // Calculate stats
        double attendanceRate = 0;
        if (records.isNotEmpty) {
          final present = records
              .where(
                (r) =>
                    r.status == AttendanceStatus.present ||
                    r.status == AttendanceStatus.excused,
              )
              .length;
          attendanceRate = (present / records.length) * 100;
        }

        // Get last 14 records for the grid
        final recentRecords = records.length > 14
            ? records.sublist(records.length - 14)
            : records;

        return GlassCard(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAttendanceHistory(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (records.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No records yet',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Percentage Indicator with Chart
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50, // Reduced size
                            height: 50,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 20, // Reduced radius
                                startDegreeOffset: 270,
                                sections: [
                                  PieChartSectionData(
                                    value: attendanceRate,
                                    color: attendanceRate >= 75
                                        ? Colors.green
                                        : (attendanceRate >= 50
                                              ? Colors.orange
                                              : Colors.red),
                                    radius: 6, // Thinner ring
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: 100 - attendanceRate,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    radius: 6,
                                    showTitle: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${attendanceRate.toInt()}%',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12, // Smaller font
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Rate',
                                style: TextStyle(
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Grid of Recent Sessions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: recentRecords.map((r) {
                                Color color;
                                switch (r.status) {
                                  case AttendanceStatus.present:
                                    color = Colors.green;
                                    break;
                                  case AttendanceStatus.absent:
                                    color = Colors.red;
                                    break;
                                  case AttendanceStatus.excused:
                                    color = Colors.orange;
                                    break;
                                  default:
                                    color = Colors.grey;
                                }
                                return Tooltip(
                                  message:
                                      '${DateFormat.MMMd().format(r.date)}: ${r.status.name.toUpperCase()}',
                                  child: Container(
                                    width: 8, // Smaller squares
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last ${recentRecords.length} sessions',
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentNotesList(
    bool isDark,
    Color primaryColor, {
    int limit = 100,
  }) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        final notes = box.values
            .where(
              (n) =>
                  (n.tags?.contains(_course.title) ?? false) ||
                  (n.tags?.contains(_course.id) ?? false),
            )
            .toList();

        final displayNotes = notes.take(limit).toList();

        if (displayNotes.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.note_alt_outlined,
              title: 'No notes yet',
              subtitle: 'Start taking notes for this course!',
            ),
          );
        }

        return Column(
          children: displayNotes
              .map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildNoteItem(
                    note.title.isNotEmpty ? note.title : 'Untitled Note',
                    '${DateFormat.Md().format(note.updatedAt)} • ${note.strokes.length} strokes',
                    Icons.description,
                    primaryColor,
                    isDark,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNoteItem(
    String title,
    String meta,
    IconData icon,
    Color primaryColor,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFAD8DCE) : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              foregroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(bool isDark, Color primaryColor) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Basic Info ---
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        Icons.calendar_view_day,
                        'SEMESTER',
                        _course.semester.isNotEmpty ? _course.semester : 'N/A',
                        '',
                        isDark,
                        primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _infoRow(
                        Icons.stars,
                        'CREDITS',
                        '${_course.credits} ECTS',
                        '',
                        isDark,
                        primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 24),

                // --- Lecture Section ---
                Text(
                  'LECTURE / COURSE',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.person_outline,
                  'INSTRUCTOR',
                  _course.professor.isNotEmpty
                      ? _course.professor
                      : 'Not Assigned',
                  '',
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.schedule,
                  'SCHEDULE',
                  '${_course.courseDay} ${_course.courseTime}'.trim().isNotEmpty
                      ? '${_course.courseDay} at ${_course.courseTime}'
                      : 'TBD',
                  _course.courseFrequency,
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.room_outlined,
                  'ROOM / LOCATION',
                  _course.location.isNotEmpty ? _course.location : 'TBD',
                  '',
                  isDark,
                  primaryColor,
                ),

                // --- Seminar Section (Only if teacher or location is provided) ---
                if (_course.seminarProfessor.isNotEmpty ||
                    _course.seminarLocation.isNotEmpty ||
                    _course.seminarDay.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                  Text(
                    'SEMINAR',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.people_alt_outlined,
                    'SEMINAR TEACHER',
                    _course.seminarProfessor.isNotEmpty
                        ? _course.seminarProfessor
                        : 'Not Assigned',
                    '',
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'SCHEDULE',
                    '${_course.seminarDay} ${_course.seminarTime}'
                            .trim()
                            .isNotEmpty
                        ? '${_course.seminarDay} at ${_course.seminarTime}'
                        : 'TBD',
                    _course.seminarFrequency,
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.place_outlined,
                    'ROOM / LOCATION',
                    _course.seminarLocation.isNotEmpty
                        ? _course.seminarLocation
                        : 'TBD',
                    '',
                    isDark,
                    primaryColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    String subValue,
    bool isDark,
    Color primaryColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (subValue.isNotEmpty)
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFAD8DCE) : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksCard(
    bool isDark,
    Color primaryColor, {
    bool showAll = false,
  }) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values
            .where((t) => t.courseId == _course.id && !t.isCompleted && !t.isDeleted)
            .toList();

        final displayTasks = showAll ? tasks : tasks.take(3).toList();

        return GlassCard(
          child: Column(
            children: [
              if (!showAll)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_repeat, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Upcoming Tasks',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${tasks.length} DUE',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: displayTasks.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No assignments',
                        subtitle: 'You are all caught up!',
                      )
                    : Column(
                        children: displayTasks
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _taskItem(t, isDark, primaryColor),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taskItem(Task task, bool isDark, Color primaryColor) {
    final accent = task.category == 'Exam'
        ? Colors.redAccent
        : (task.category == 'Project' ? Colors.orange : primaryColor);
    final due = task.dueDate != null
        ? DateFormat.MMMd().format(task.dueDate!)
        : 'No Date';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                due.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.more_horiz, size: 16, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          if (task.progress > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: task.progress / 100,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AddGradeDialog extends StatefulWidget {
  final String courseId;
  final Grade? grade;
  const AddGradeDialog({super.key, required this.courseId, this.grade});

  @override
  State<AddGradeDialog> createState() => AddGradeDialogState();
}

class AddGradeDialogState extends State<AddGradeDialog> {
  late TextEditingController _titleController;
  late TextEditingController _scoreController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.grade?.title ?? '');
    _scoreController = TextEditingController(
      text: widget.grade?.score.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.grade != null
          ? (widget.grade!.weight * 100).toInt().toString()
          : '',
    );
  }

  void _save() async {
    if (_titleController.text.isNotEmpty && _scoreController.text.isNotEmpty) {
      final weightPercent = double.tryParse(_weightController.text) ?? 100;
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );

      if (widget.grade != null) {
        widget.grade!.title = _titleController.text;
        widget.grade!.score = double.tryParse(_scoreController.text) ?? 0;
        widget.grade!.weight = weightPercent / 100.0;
        await courseProvider.saveGrade(widget.grade!);
      } else {
        final grade = Grade.create(
          title: _titleController.text,
          score: double.tryParse(_scoreController.text) ?? 0,
          maxScore: 100.0, // Default to percentage based (out of 100)
          weight: weightPercent / 100.0,
          courseId: widget.courseId,
        );
        await courseProvider.saveGrade(grade);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.grade != null ? 'Edit Grade' : 'Add Grade',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Assignment Title',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Grade (%)',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Weight (%)',
                hintText: 'e.g. 20',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
