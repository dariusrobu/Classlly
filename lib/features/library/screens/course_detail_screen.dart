import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/note_models.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/features/library/screens/add_task_screen.dart';
import 'package:classlly/features/canvas/providers/canvas_provider.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  void _addNote(BuildContext context) {
    final note = Note.create(title: '${course.title} Note');
    note.tags = [course.title, course.id]; // Link to course
    Provider.of<CanvasProvider>(context, listen: false).setNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CanvasScreen()),
    );
  }

  void _addTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskScreen(initialCourseId: course.id),
    );
  }

  void _addGrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddGradeDialog(courseId: course.id),
    );
  }

  void _addAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddAttendanceDialog(courseId: course.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width > 900)
              const DashboardSidebar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context, isDark, primaryColor),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, isDark, primaryColor),
                    const SizedBox(height: 32),
                    _buildMainGrid(context, isDark, primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _actionButton(
            context,
            'Add Note',
            Icons.edit_note,
            () => _addNote(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            'Add Task',
            Icons.check_circle_outline,
            () => _addTask(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            'Add Grade',
            Icons.grade_outlined,
            () => _addGrade(context),
            isDark,
            primaryColor,
          ),
          const SizedBox(width: 12),
          _actionButton(
            context,
            'Mark Attendance',
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
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return _GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'BACK TO COURSES',
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
              const SizedBox(height: 12),
              Text(
                course.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 40,
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
                    course.professor.isNotEmpty
                        ? course.professor
                        : 'No Instructor',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFAD8DCE)
                          : Colors.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    course.credits > 0
                        ? '${course.credits} Credits'
                        : 'Credits TBD',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFAD8DCE)
                          : Colors.grey[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
              final courseGrades = gradeBox.values
                  .where((g) => g.courseId == course.id)
                  .toList();
              double avg = 0;
              if (courseGrades.isNotEmpty) {
                double totalWeightedScore = 0;
                double totalWeight = 0;
                for (var g in courseGrades) {
                  totalWeightedScore +=
                      ((g.score / g.maxScore) * 100) * g.weight;
                  totalWeight += g.weight;
                }
                if (totalWeight > 0) {
                  avg = totalWeightedScore / totalWeight;
                }
              }

              return ValueListenableBuilder(
                valueListenable: Hive.box<Attendance>(
                  NotesRepository.attendanceBoxName,
                ).listenable(),
                builder: (context, Box<Attendance> attBox, _) {
                  final courseAtt = attBox.values
                      .where((a) => a.courseId == course.id)
                      .toList();
                  double attendance = 0;
                  if (courseAtt.isNotEmpty) {
                    final present = courseAtt
                        .where((r) => r.status == AttendanceStatus.present)
                        .length;
                    attendance = (present / courseAtt.length) * 100;
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerStatItem(
                        'CURRENT GRADE',
                        courseGrades.isEmpty
                            ? 'N/A'
                            : '${avg.toStringAsFixed(1)}%',
                        courseGrades.isEmpty ? '-' : 'Good',
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _headerStatItem(
                        'ATTENDANCE',
                        courseAtt.isEmpty ? 'N/A' : '${attendance.toInt()}%',
                        courseAtt.isEmpty ? '-' : 'Steady',
                        isDark,
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
    String trend,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 140),
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
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              if (trend != '-' && trend != 'N/A')
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Colors.greenAccent.shade400,
                ),
              const SizedBox(width: 2),
              Text(
                trend,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (trend == 'N/A' || trend == '-')
                      ? Colors.grey
                      : Colors.greenAccent.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(BuildContext context, bool isDark, Color primaryColor) {
    // 2/3 left, 1/3 right layout
    final isWide = MediaQuery.of(context).size.width > 1100;

    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isWide ? 2 : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Performance History',
                Icons.analytics_outlined,
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildPerformanceCharts(isDark, primaryColor),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(
                    'Recent Lecture Notes',
                    Icons.edit_note,
                    primaryColor,
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentNotesList(isDark, primaryColor), // Dynamic notes
            ],
          ),
        ),
        if (isWide) const SizedBox(width: 32) else const SizedBox(height: 32),
        Expanded(
          flex: isWide ? 1 : 0,
          child: Column(
            children: [
              _buildCourseInfoCard(isDark, primaryColor),
              const SizedBox(height: 32),
              _buildTasksCard(isDark, primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCharts(bool isDark, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 800 ? 3 : 1;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4, // Made smaller height
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildGoalChart(isDark, primaryColor),
            _buildTrendChart(isDark, primaryColor),
            _buildAttendanceChart(isDark, primaryColor),
          ],
        );
      },
    );
  }

  Widget _buildGoalChart(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Grade>(
        NotesRepository.gradeBoxName,
      ).listenable(),
      builder: (context, Box<Grade> box, _) {
        final courseGrades = box.values
            .where((g) => g.courseId == course.id)
            .toList();
        double currentGrade = 0;
        if (courseGrades.isNotEmpty) {
          double totalWeightedScore = 0;
          double totalWeight = 0;
          for (var g in courseGrades) {
            totalWeightedScore += ((g.score / g.maxScore) * 100) * g.weight;
            totalWeight += g.weight;
          }
          if (totalWeight > 0) {
            currentGrade = totalWeightedScore / totalWeight;
          }
        }

        return _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grade Goal',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Icon(Icons.edit_square, size: 14, color: primaryColor),
                ],
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: currentGrade,
                              color: primaryColor,
                              radius: 8,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: 100 - currentGrade,
                              color: Colors.white10,
                              radius: 8,
                              showTitle: false,
                            ),
                          ],
                          startDegreeOffset: 270,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${currentGrade.toInt()}%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'GPA',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11,
                  ),
                  children: [
                    const TextSpan(text: 'Goal: '),
                    TextSpan(
                      text: '95%',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
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

  Widget _buildTrendChart(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Grade>(
        NotesRepository.gradeBoxName,
      ).listenable(),
      builder: (context, Box<Grade> box, _) {
        final courseGrades =
            box.values.where((g) => g.courseId == course.id).toList()
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

        return _GlassCard(
          padding: const EdgeInsets.all(16),
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
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 5,
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
              const SizedBox(height: 4),
              if (courseGrades.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'START',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'NOW',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'No grade data',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
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
            box.values.where((r) => r.courseId == course.id).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

        return _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance History',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (records.isEmpty)
                const Center(
                  child: Text(
                    'No records',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: records.take(8).map((r) {
                    final isPresent = r.status == AttendanceStatus.present;
                    return Container(
                      width: 6,
                      height: isPresent ? 40 : 15,
                      decoration: BoxDecoration(
                        color: isPresent
                            ? primaryColor.withValues(alpha: 0.6)
                            : Colors.redAccent.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentNotesList(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        final notes = box.values
            .where(
              (n) =>
                  (n.tags?.contains(course.title) ?? false) ||
                  (n.tags?.contains(course.id) ?? false),
            )
            .toList();

        final displayNotes = notes.isEmpty
            ? box.values.take(3).toList()
            : notes.take(3).toList();

        if (displayNotes.isEmpty) {
          return const Center(
            child: Text(
              'No notes found for this course.',
              style: TextStyle(color: Colors.grey),
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
    return _GlassCard(
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
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Course Information',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  course.professor.isNotEmpty
                      ? course.professor
                      : 'Not Assigned',
                  '',
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.schedule,
                  'SCHEDULE',
                  '${course.courseDay} ${course.courseTime}'.trim().isNotEmpty
                      ? '${course.courseDay} at ${course.courseTime}'
                      : 'TBD',
                  course.courseFrequency,
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.room_outlined,
                  'ROOM / LOCATION',
                  course.location.isNotEmpty ? course.location : 'TBD',
                  '',
                  isDark,
                  primaryColor,
                ),

                // --- Seminar Section (Only if teacher or location is provided) ---
                if (course.seminarProfessor.isNotEmpty ||
                    course.seminarLocation.isNotEmpty ||
                    course.seminarDay.isNotEmpty) ...[
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
                    course.seminarProfessor.isNotEmpty
                        ? course.seminarProfessor
                        : 'Not Assigned',
                    '',
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'SCHEDULE',
                    '${course.seminarDay} ${course.seminarTime}'
                            .trim()
                            .isNotEmpty
                        ? '${course.seminarDay} at ${course.seminarTime}'
                        : 'TBD',
                    course.seminarFrequency,
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.place_outlined,
                    'ROOM / LOCATION',
                    course.seminarLocation.isNotEmpty
                        ? course.seminarLocation
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

  Widget _buildTasksCard(bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values
            .where((t) => t.courseId == course.id && !t.isCompleted)
            .toList();

        return _GlassCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
                child: tasks.isEmpty
                    ? const Text(
                        'No upcoming tasks',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(
                        children: tasks
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _taskItem(t, isDark, primaryColor),
                              ),
                            )
                            .toList(),
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  child: const Text('Show All Assignments'),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2E2E2E).withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AddGradeDialog extends StatefulWidget {
  final String courseId;
  const _AddGradeDialog({required this.courseId});

  @override
  State<_AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<_AddGradeDialog> {
  final _titleController = TextEditingController();
  final _scoreController = TextEditingController();
  final _weightController = TextEditingController();
  final NotesRepository _repo = NotesRepository();

  void _save() async {
    if (_titleController.text.isNotEmpty && _scoreController.text.isNotEmpty) {
      final weightPercent = double.tryParse(_weightController.text) ?? 100;
      final grade = Grade.create(
        title: _titleController.text,
        score: double.tryParse(_scoreController.text) ?? 0,
        maxScore: 100.0, // Default to percentage based (out of 100)
        weight: weightPercent / 100.0,
        courseId: widget.courseId,
      );
      await _repo.saveGrade(grade);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Grade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Assignment Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreController,
            decoration: const InputDecoration(labelText: 'Grade (%)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (%)',
              hintText: 'e.g. 20',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AddAttendanceDialog extends StatefulWidget {
  final String courseId;
  const _AddAttendanceDialog({required this.courseId});

  @override
  State<_AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<_AddAttendanceDialog> {
  AttendanceStatus _status = AttendanceStatus.present;
  DateTime _date = DateTime.now();
  final NotesRepository _repo = NotesRepository();

  void _save() async {
    final att = Attendance.create(
      date: _date,
      status: _status,
      courseId: widget.courseId,
    );
    await _repo.saveAttendance(att);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark Attendance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AttendanceStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: AttendanceStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.toString().split('.').last.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
