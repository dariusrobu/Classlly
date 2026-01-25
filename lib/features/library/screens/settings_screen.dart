import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:classlly/main.dart'; // For ThemeProvider
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/features/library/providers/academic_calendar_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:classlly/data/models/user_preferences_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // On mobile, show a standard AppBar. On desktop, the custom header is used.
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.settings),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : Colors.black87,
              ),
            )
          : null,
      drawer: isMobile ? const Drawer(child: DashboardSidebar()) : null,
      body: Row(
        children: [
          // Sidebar (Only on Desktop)
          if (!isMobile) const DashboardSidebar(),

          // Main Content
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark, isMobile),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 60,
                        vertical: 40,
                      ),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                AppLocalizations.of(context)!.appearance,
                                AppLocalizations.of(context)!.appearanceDesc,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildGlassPanel(
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    _buildThemeRow(context, isDark),
                                    Divider(
                                      height: 1,
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                    _buildAccentColorRow(context, isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),
                              _buildSectionHeader(
                                AppLocalizations.of(context)!.academicCalendar,
                                AppLocalizations.of(context)!.calendarDesc,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildAcademicCalendar(context, isDark),
                              const SizedBox(height: 48),
                              _buildSectionHeader(
                                AppLocalizations.of(context)!.notifications,
                                AppLocalizations.of(context)!.notificationsDesc,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildNotificationSettings(isDark),
                              const SizedBox(height: 48),
                              _buildSectionHeader(
                                AppLocalizations.of(context)!.syncCloud,
                                AppLocalizations.of(context)!.syncCloudDesc,
                                isDark,
                              ),
                              const SizedBox(height: 24),
                              _buildCloudSyncCard(context, isDark),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isMobile) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.grey : Colors.grey[800];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(Icons.menu, color: subColor),
              ),
            ),
          Text(
            AppLocalizations.of(context)!.settings,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const VerticalDivider(width: 32, indent: 24, endIndent: 24),
          Text(AppLocalizations.of(context)!.workspace, style: TextStyle(fontSize: 12, color: subColor)),
          Icon(Icons.chevron_right, size: 14, color: subColor),
          Text(
            AppLocalizations.of(context)!.appearance,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildThemeRow(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(context, Icons.dark_mode, isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.interfaceTheme,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.themeDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  child: _themeBtn(
                    context,
                    AppLocalizations.of(context)!.light,
                    themeProvider.themeMode == ThemeMode.light,
                    isDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  child: _themeBtn(
                    context,
                    AppLocalizations.of(context)!.dark,
                    themeProvider.themeMode == ThemeMode.dark,
                    isDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  child: _themeBtn(
                    context,
                    AppLocalizations.of(context)!.system,
                    themeProvider.themeMode == ThemeMode.system,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeBtn(
    BuildContext context,
    String label,
    bool active,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? Colors.white
              : (isDark ? Colors.grey : Colors.grey[600]),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccentColorRow(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.accentColor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.accentColorDesc,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AppTheme.accentColors.map((color) {
              return _colorDot(
                color,
                themeProvider.accentColor.toARGB32() == color.toARGB32(),
                isDark,
                () => themeProvider.setAccentColor(color),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: active
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                )
              : null,
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: active
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildCloudSyncCard(BuildContext context, bool isDark) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final lastSynced = libraryProvider.lastSynced != null
        ? DateFormat('MMM d, HH:mm').format(libraryProvider.lastSynced!)
        : AppLocalizations.of(context)!.never;

    return _buildGlassPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                _iconBox(context, Icons.cloud_done_rounded, isDark, size: 48),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.cloudSyncTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.lastSynced(lastSynced),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => libraryProvider.initSync(),
                  icon: const Icon(Icons.sync, size: 16),
                  label: Text(AppLocalizations.of(context)!.syncNow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.supabaseSecurity,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    String title,
    String subtitle,
    bool val,
    bool isDark,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(context, Icons.contrast, isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicCalendar(BuildContext context, bool isDark) {
    final calendarProvider = Provider.of<AcademicCalendarProvider>(context);
    final periods = calendarProvider.periods;
    final events = calendarProvider.events;

    return _buildGlassPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.periods,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showLoadTemplateDialog(context),
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(AppLocalizations.of(context)!.loadTemplate),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.clearCalendar),
                        content: Text(
                          AppLocalizations.of(context)!.clearCalendarConfirm,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              Provider.of<AcademicCalendarProvider>(
                                context,
                                listen: false,
                              ).clearCalendar();
                              Navigator.pop(context);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.clearAll,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: Text(AppLocalizations.of(context)!.delete),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddPeriodDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context)!.addPeriod),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (periods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppLocalizations.of(context)!.noPeriodsAdded,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...periods.map(
                (p) => _buildPeriodItem(context, p, isDark, calendarProvider),
              ),
            const SizedBox(height: 24),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.holidaysFreeDays,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEventDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context)!.addEvent),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppLocalizations.of(context)!.noEventsAdded,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...events.map(
                (e) => _buildEventItem(context, e, isDark, calendarProvider),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodItem(
    BuildContext context,
    AcademicPeriod period,
    bool isDark,
    AcademicCalendarProvider provider,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPeriodIcon(period.type),
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              period.type.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
            onPressed: () => provider.deletePeriod(period.id),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    AcademicEvent event,
    bool isDark,
    AcademicCalendarProvider provider,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.type == AcademicEventType.holiday
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              event.type == AcademicEventType.holiday
                  ? Icons.celebration
                  : Icons.weekend,
              size: 20,
              color: event.type == AcademicEventType.holiday
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  dateFormat.format(event.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
            onPressed: () => provider.deleteEvent(event.id),
          ),
        ],
      ),
    );
  }

  IconData _getPeriodIcon(AcademicPeriodType type) {
    switch (type) {
      case AcademicPeriodType.teaching:
        return Icons.school;
      case AcademicPeriodType.exam:
        return Icons.assignment_late;
      case AcademicPeriodType.session:
        return Icons.event_note;
      case AcademicPeriodType.retake:
        return Icons.restore;
      case AcademicPeriodType.holiday:
        return Icons.celebration;
    }
  }

  void _showAddPeriodDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));
    AcademicPeriodType type = AcademicPeriodType.teaching;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addPeriod),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Period Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AcademicPeriodType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AcademicPeriodType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => type = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => startDate = picked);
                            }
                          },
                          child: Text(
                            'Start: ${DateFormat('MM/dd/yy').format(startDate)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => endDate = picked);
                            }
                          },
                          child: Text(
                            'End: ${DateFormat('MM/dd/yy').format(endDate)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Provider.of<AcademicCalendarProvider>(
                      context,
                      listen: false,
                    ).addPeriod(
                      name: nameController.text,
                      startDate: startDate,
                      endDate: endDate,
                      type: type,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.addNote.split(' ')[0]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    DateTime date = DateTime.now();
    AcademicEventType type = AcademicEventType.holiday;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addEvent),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Event Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AcademicEventType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AcademicEventType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => type = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    },
                    child: Text('Date: ${DateFormat('MM/dd/yy').format(date)}'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Provider.of<AcademicCalendarProvider>(
                      context,
                      listen: false,
                    ).addEvent(
                      name: nameController.text,
                      date: date,
                      type: type,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context)!.addNote.split(' ')[0]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLoadTemplateDialog(BuildContext context) {
    final provider = Provider.of<AcademicCalendarProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.loadTemplate),
        content: SizedBox(
          width: 400,
          child: FutureBuilder<List<dynamic>>(
            future: provider.getAvailableTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Text('Could not load templates.');
              }

              final templates = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return ListTile(
                    title: Text(t['universityName']),
                    subtitle: Text('Year: ${t['academicYear']}'),
                    onTap: () {
                      provider.loadTemplate(t);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Loaded ${t['universityName']} template',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(
    BuildContext context,
    IconData icon,
    bool isDark, {
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildNotificationSettings(bool isDark) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserPreferences>(
        NotesRepository.preferencesBoxName,
      ).listenable(),
      builder: (context, Box<UserPreferences> box, _) {
        final prefs = box.get('user_prefs') ?? UserPreferences();

        void savePrefs() {
          if (prefs.isInBox) {
            prefs.save();
          } else {
            box.put('user_prefs', prefs);
          }
        }

        return _buildGlassPanel(
          isDark: isDark,
          child: Column(
            children: [
              _buildToggleRow(
                context,
                AppLocalizations.of(context)!.lectureReminders,
                AppLocalizations.of(context)!.lectureRemindersDesc,
                prefs.lectureReminders,
                isDark,
                (val) {
                  prefs.lectureReminders = val;
                  savePrefs();
                },
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              _buildToggleRow(
                context,
                AppLocalizations.of(context)!.taskDeadlines,
                AppLocalizations.of(context)!.taskDeadlinesDesc,
                prefs.taskDeadlines,
                isDark,
                (val) {
                  prefs.taskDeadlines = val;
                  savePrefs();
                },
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
              ),
              _buildToggleRow(
                context,
                AppLocalizations.of(context)!.appUpdates,
                AppLocalizations.of(context)!.appUpdatesDesc,
                prefs.appUpdates,
                isDark,
                (val) {
                  prefs.appUpdates = val;
                  savePrefs();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
