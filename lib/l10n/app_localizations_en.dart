// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Classlly';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get dashboard => 'Dashboard';

  @override
  String get notes => 'Notes';

  @override
  String get courses => 'Courses';

  @override
  String get tasks => 'Tasks';

  @override
  String get calendar => 'Calendar';

  @override
  String get archive => 'Archive';

  @override
  String get settings => 'Settings';

  @override
  String get recentNotes => 'Recent Notes';

  @override
  String get dailyAgenda => 'Daily Agenda';

  @override
  String get performanceOverview => 'Performance Overview';

  @override
  String get attendance => 'Attendance';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get addNote => 'Add Note';

  @override
  String get addTask => 'Add Task';

  @override
  String get addGrade => 'Add Grade';

  @override
  String get markAttendance => 'Mark Attendance';
}
