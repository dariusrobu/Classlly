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

  void _showGradeHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ValueListenableBuilder(
        valueListenable: Hive.box<Grade>(NotesRepository.gradeBoxName).listenable(),
        builder: (context, Box<Grade> box, _) {
          final grades = box.values
              .where((g) => g.courseId == widget.course.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Grade History',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: grades.isEmpty
                    ? const Center(child: Text('No grades recorded'))
                    : ListView.builder(
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          final grade = grades[index];
                          return ListTile(
                            title: Text(grade.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${DateFormat.yMMMd().format(grade.date)} • Weight: ${(grade.weight * 100).toInt()}%'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${grade.score}/${grade.maxScore}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => _AddGradeDialog(
                                          courseId: widget.course.id,
                                          grade: grade,
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Grade'),
                                          content: const Text('Are you sure you want to delete this grade record?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await grade.delete();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
        valueListenable: Hive.box<Attendance>(NotesRepository.attendanceBoxName).listenable(),
        builder: (context, Box<Attendance> box, _) {
          final records = box.values
              .where((r) => r.courseId == widget.course.id)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Attendance History',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('No attendance records'))
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isPresent = record.status == AttendanceStatus.present;
                          final isExcused = record.status == AttendanceStatus.excused;
                          final color = isPresent ? Colors.green : (isExcused ? Colors.orange : Colors.red);
                          return ListTile(
                            leading: Icon(
                              isPresent ? Icons.check_circle : (isExcused ? Icons.info : Icons.cancel),
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
                                        builder: (context) => _AddAttendanceDialog(
                                          courseId: widget.course.id,
                                          attendance: record,
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Record'),
                                          content: const Text('Are you sure you want to delete this attendance record?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await record.delete();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

              double avg = 0;
              int gradeTrend = 0;

              if (courseGrades.isNotEmpty) {
                // Calculate current average
                double totalWeightedScore = 0;
                double totalWeight = 0;
                for (var g in courseGrades) {
                  totalWeightedScore += ((g.score / g.maxScore) * 100) * g.weight;
                  totalWeight += g.weight;
                }
                avg = totalWeight > 0 ? totalWeightedScore / totalWeight : 0;

                // Calculate previous average (excluding last)
                if (courseGrades.length > 1) {
                  double prevTotalWeightedScore = 0;
                  double prevTotalWeight = 0;
                  for (int i = 0; i < courseGrades.length - 1; i++) {
                    final g = courseGrades[i];
                    prevTotalWeightedScore += ((g.score / g.maxScore) * 100) * g.weight;
                    prevTotalWeight += g.weight;
                  }
                  double prevAvg = prevTotalWeight > 0 ? prevTotalWeightedScore / prevTotalWeight : 0;
                  gradeTrend = avg > prevAvg ? 1 : (avg < prevAvg ? -1 : 0);
                }
              }

              return ValueListenableBuilder(
                valueListenable: Hive.box<Attendance>(
                  NotesRepository.attendanceBoxName,
                ).listenable(),
                builder: (context, Box<Attendance> attBox, _) {
                  final courseAtt = attBox.values
                      .where((a) => a.courseId == widget.course.id)
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

                  double attendance = 0;
                  int attTrend = 0;

                  if (courseAtt.isNotEmpty) {
                    final presentCount = courseAtt
                        .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.excused)
                        .length;
                    attendance = (presentCount / courseAtt.length) * 100;

                    if (courseAtt.length > 1) {
                      final prevPresentCount = courseAtt
                          .take(courseAtt.length - 1)
                          .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.excused)
                          .length;
                      double prevAttendance = (prevPresentCount / (courseAtt.length - 1)) * 100;
                      attTrend = attendance > prevAttendance ? 1 : (attendance < prevAttendance ? -1 : 0);
                    }
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _headerStatItem(
                        'CURRENT GRADE',
                        courseGrades.isEmpty ? 'N/A' : '${avg.toStringAsFixed(1)}%',
                        gradeTrend,
                        isDark,
                      ),
                      const SizedBox(width: 16),
                      _headerStatItem(
                        'ATTENDANCE',
                        courseAtt.isEmpty ? 'N/A' : '${attendance.toInt()}%',
                        attTrend,
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
    int trendDirection,
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
              if (trendDirection != 0)
                Icon(
                  trendDirection > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendDirection > 0 ? Colors.greenAccent.shade400 : Colors.redAccent,
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
                  InkWell(
                    onTap: () => _showGradeHistory(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: primaryColor),
                      ],
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

        // Calculate stats
        double attendanceRate = 0;
        if (records.isNotEmpty) {
          final present = records
              .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.excused)
              .length;
          attendanceRate = (present / records.length) * 100;
        }

        // Get last 14 records for the grid
        final recentRecords = records.length > 14
            ? records.sublist(records.length - 14)
            : records;

        return _GlassCard(
          padding: const EdgeInsets.all(16),
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
                      fontSize: 12,
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No records yet',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Percentage Indicator with Chart
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              startDegreeOffset: 270,
                              sections: [
                                PieChartSectionData(
                                  value: attendanceRate,
                                  color: attendanceRate >= 75
                                      ? Colors.green
                                      : (attendanceRate >= 50
                                          ? Colors.orange
                                          : Colors.red),
                                  radius: 8,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: 100 - attendanceRate,
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  radius: 8,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Rate',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[500] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Grid of Recent Sessions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
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
                                message: '${DateFormat.MMMd().format(r.date)}: ${r.status.name.toUpperCase()}',
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last ${recentRecords.length} sessions',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
  final Grade? grade;
  const _AddGradeDialog({required this.courseId, this.grade});

  @override
  State<_AddGradeDialog> createState() => _AddGradeDialogState();
}

class _AddGradeDialogState extends State<_AddGradeDialog> {
  late TextEditingController _titleController;
  late TextEditingController _scoreController;
  late TextEditingController _weightController;
  final NotesRepository _repo = NotesRepository();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.grade?.title ?? '');
    _scoreController = TextEditingController(text: widget.grade?.score.toString() ?? '');
    _weightController = TextEditingController(text: widget.grade != null ? (widget.grade!.weight * 100).toInt().toString() : '');
  }

  void _save() async {
    if (_titleController.text.isNotEmpty && _scoreController.text.isNotEmpty) {
      final weightPercent = double.tryParse(_weightController.text) ?? 100;
      if (widget.grade != null) {
        widget.grade!.title = _titleController.text;
        widget.grade!.score = double.tryParse(_scoreController.text) ?? 0;
        widget.grade!.weight = weightPercent / 100.0;
        await _repo.saveGrade(widget.grade!);
      } else {
        final grade = Grade.create(
          title: _titleController.text,
          score: double.tryParse(_scoreController.text) ?? 0,
          maxScore: 100.0, // Default to percentage based (out of 100)
          weight: weightPercent / 100.0,
          courseId: widget.courseId,
        );
        await _repo.saveGrade(grade);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.grade != null ? 'Edit Grade' : 'Add Grade'),
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
  final Attendance? attendance;
  const _AddAttendanceDialog({required this.courseId, this.attendance});

  @override
  State<_AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<_AddAttendanceDialog> {
  late AttendanceStatus _status;
  late DateTime _date;
  final NotesRepository _repo = NotesRepository();

  @override
  void initState() {
    super.initState();
    _status = widget.attendance?.status ?? AttendanceStatus.present;
    _date = widget.attendance?.date ?? DateTime.now();
  }

  void _save() async {
    if (widget.attendance != null) {
      widget.attendance!.status = _status;
      widget.attendance!.date = _date;
      await _repo.saveAttendance(widget.attendance!);
    } else {
      final att = Attendance.create(
        date: _date,
        status: _status,
        courseId: widget.courseId,
      );
      await _repo.saveAttendance(att);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.attendance != null ? 'Edit Attendance' : 'Mark Attendance'),
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