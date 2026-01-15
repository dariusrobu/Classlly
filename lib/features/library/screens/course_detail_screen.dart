import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:classlly/core/theme/app_theme.dart';

class CourseDetailScreen extends StatelessWidget {
  final String title;
  final String prof;
  final Color color;
  const CourseDetailScreen({super.key, required this.title, required this.prof, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F2F4),
      body: Row(
        children: [
          _buildMiniSidebar(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(context, isDark),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: Column(children: [_buildPerformanceSection(isDark), const SizedBox(height: 32), _buildRecentNotesSection(isDark), const SizedBox(height: 32), _buildResourcesSection(isDark)])),
                      const SizedBox(width: 32),
                      Expanded(flex: 1, child: Column(children: [_buildCourseInfoCard(isDark), const SizedBox(height: 32), _buildUpcomingTasksCard(isDark)])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSidebar(BuildContext context, bool isDark) {
    return Container(
      width: 80,
      decoration: BoxDecoration(color: isDark ? const Color(0xFF121212) : Colors.white, border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _sidebarIcon(Icons.biotech, isBrand: true),
          const SizedBox(height: 48),
          _sidebarIcon(Icons.dashboard, isActive: false, onTap: () => Navigator.pop(context)),
          _sidebarIcon(Icons.import_contacts, isActive: true),
          const Spacer(),
          _sidebarIcon(Icons.add, isAction: true),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, {bool isActive = false, bool isBrand = false, bool isAction = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: isBrand ? AppTheme.primaryPurple : (isActive ? AppTheme.primaryPurple.withOpacity(0.1) : (isAction ? AppTheme.primaryPurple : Colors.transparent)), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: (isBrand || isAction) ? Colors.white : (isActive ? AppTheme.primaryPurple : Colors.grey), size: 24),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, bool isDark) {
    return _buildGlassPanel(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Row(children: [Icon(Icons.arrow_back, size: 14, color: AppTheme.primaryPurple), SizedBox(width: 8), Text("BACK TO COURSES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple, letterSpacing: 1.5))])),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.person, size: 16, color: Colors.grey), const SizedBox(width: 6), Text(prof, style: const TextStyle(color: Colors.grey, fontSize: 14))]),
            ],
          ),
          Row(children: [_headerStat("Grade", "94%", "+2.1%"), const SizedBox(width: 24), _headerStat("Attend.", "98%", "+0.5%")]),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String val, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.vibrantPurple)),
          Row(children: [Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(trend, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildCard(child: const Text("Grade Goal: 88%", style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(width: 20),
        Expanded(child: _buildCard(child: const Text("Grade Trend: +4.2%", style: TextStyle(fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildRecentNotesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Lecture Notes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _noteListItem("Cellular Respiration", "Oct 12, 2023", Icons.science),
      ],
    );
  }

  Widget _noteListItem(String title, String meta, IconData icon) {
    return _buildCard(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primaryPurple)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(meta, style: const TextStyle(color: Colors.grey, fontSize: 12))])), ElevatedButton(onPressed: () {}, child: const Text("Open"))]));
  }

  Widget _buildResourcesSection(bool isDark) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Resources", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 16), Text("Syllabus.pdf", style: TextStyle(color: Colors.grey))]);
  }

  Widget _buildCourseInfoCard(bool isDark) {
    return _buildCard(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Course Information", style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 16), Text("Mon / Wed / Fri", style: TextStyle(fontSize: 14))]));
  }

  Widget _buildUpcomingTasksCard(bool isDark) {
    return _buildCard(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Upcoming Tasks", style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 16), Text("Lab Report - Due Friday", style: TextStyle(fontSize: 13))]));
  }

  Widget _buildGlassPanel({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(padding: padding, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), border: Border.all(color: Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(20)), child: child)));
  }

  Widget _buildCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(24)}) {
    return Container(padding: padding, decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))), child: child);
  }
}