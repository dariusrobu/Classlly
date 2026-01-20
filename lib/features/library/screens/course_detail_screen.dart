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
import 'package:classlly/features/library/widgets/empty_state.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNote(BuildContext context) {
    final note = Note.create(title: '${widget.course.title} Note');
    note.tags = [widget.course.title, widget.course.id]; // Link to course
    Provider.of<CanvasProvider>(context, listen: false).setNote(note);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CanvasScreen()),
    );
  }

  void _addTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTaskScreen(initialCourseId: widget.course.id),
    );
  }

  void _addGrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddGradeDialog(courseId: widget.course.id),
    );
  }

  void _addAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddAttendanceDialog(courseId: widget.course.id),
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
              child: Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderSection(
                                      context, isDark, primaryColor),
                                  const SizedBox(height: 24),
                                  _buildQuickActions(
                                      context, isDark, primaryColor),
                                  const SizedBox(height: 24),
                                  TabBar(
                                    controller: _tabController,
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    dividerColor: Colors.transparent,
                                    labelColor: primaryColor,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: primaryColor,
                                    tabs: const [
                                      Tab(text: 'Overview'),
                                      Tab(text: 'Notes'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
      BuildContext context, bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceCharts(isDark, primaryColor),
          const SizedBox(height: 32),
          _buildCourseInfoCard(isDark, primaryColor),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
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
              Expanded(
                child: _buildTasksCard(isDark, primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: _buildRecentNotesList(isDark, primaryColor, limit: 100),
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
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
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
                widget.course.title,
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
                    widget.course.professor.isNotEmpty
                        ? widget.course.professor
                        : 'No Instructor',
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
                  .where((g) => g.courseId == widget.course.id)
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
                      .where((a) => a.courseId == widget.course.id)
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
            ],
          ),
        ],
      ),
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
            .where((g) => g.courseId == widget.course.id)
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
            box.values.where((g) => g.courseId == widget.course.id).toList()
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
            box.values.where((r) => r.courseId == widget.course.id).toList()
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

  Widget _buildRecentNotesList(bool isDark, Color primaryColor,
      {int limit = 100}) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Note>(NotesRepository.boxName).listenable(),
      builder: (context, Box<Note> box, _) {
        final notes = box.values
            .where(
              (n) =>
                  (n.tags?.contains(widget.course.title) ?? false) ||
                  (n.tags?.contains(widget.course.id) ?? false),
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
                        widget.course.semester.isNotEmpty
                            ? widget.course.semester
                            : 'N/A',
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
                        '${widget.course.credits} ECTS',
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
                  widget.course.professor.isNotEmpty
                      ? widget.course.professor
                      : 'Not Assigned',
                  '',
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.schedule,
                  'SCHEDULE',
                  '${widget.course.courseDay} ${widget.course.courseTime}'
                          .trim()
                          .isNotEmpty
                      ? '${widget.course.courseDay} at ${widget.course.courseTime}'
                      : 'TBD',
                  widget.course.courseFrequency,
                  isDark,
                  primaryColor,
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.room_outlined,
                  'ROOM / LOCATION',
                  widget.course.location.isNotEmpty
                      ? widget.course.location
                      : 'TBD',
                  '',
                  isDark,
                  primaryColor,
                ),

                // --- Seminar Section (Only if teacher or location is provided) ---
                if (widget.course.seminarProfessor.isNotEmpty ||
                    widget.course.seminarLocation.isNotEmpty ||
                    widget.course.seminarDay.isNotEmpty) ...[
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
                    widget.course.seminarProfessor.isNotEmpty
                        ? widget.course.seminarProfessor
                        : 'Not Assigned',
                    '',
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'SCHEDULE',
                    '${widget.course.seminarDay} ${widget.course.seminarTime}'
                            .trim()
                            .isNotEmpty
                        ? '${widget.course.seminarDay} at ${widget.course.seminarTime}'
                        : 'TBD',
                    widget.course.seminarFrequency,
                    isDark,
                    primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    Icons.place_outlined,
                    'ROOM / LOCATION',
                    widget.course.seminarLocation.isNotEmpty
                        ? widget.course.seminarLocation
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

  Widget _buildTasksCard(bool isDark, Color primaryColor,
      {bool showAll = false}) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>(NotesRepository.taskBoxName).listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values
            .where((t) => t.courseId == widget.course.id && !t.isCompleted)
            .toList();

        final displayTasks = showAll ? tasks : tasks.take(3).toList();

        return _GlassCard(
          child: Column(
            children: [
              if (!showAll)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
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