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

  @override
  String get taskDashboard => 'Task Dashboard';

  @override
  String totalTasks(int count) {
    return 'You have $count tasks in total.';
  }

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get todo => 'To Do';

  @override
  String get highPriority => 'High Priority';

  @override
  String get done => 'Done';

  @override
  String get priority => 'Priority';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get noDueDate => 'No due date';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get clearCompleted => 'Clear Completed';

  @override
  String get viewCalendar => 'View Calendar';

  @override
  String get freeDay => 'Free day!';

  @override
  String get noTasksScheduled => 'You have no tasks scheduled for today.';

  @override
  String get nothingScheduled => 'Nothing scheduled';

  @override
  String get timelineClear => 'Your timeline is clear for this day.';

  @override
  String get today => 'Today';

  @override
  String get month => 'Month';

  @override
  String get week => 'Week';

  @override
  String get academicScheduleDesc =>
      'Manage your academic schedule and deadlines.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get none => 'None';

  @override
  String get untitled => 'Untitled';

  @override
  String get allDay => 'All Day';

  @override
  String get lecture => 'Lecture';

  @override
  String get seminar => 'SEMINAR';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceDesc =>
      'Customize how Classlly looks and feels on your device.';

  @override
  String get interfaceTheme => 'Interface Theme';

  @override
  String get themeDesc => 'Choose between light, dark, or system default.';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get accentColorDesc =>
      'Select the glowing accent used for buttons and highlights.';

  @override
  String get academicCalendar => 'Academic Calendar';

  @override
  String get calendarDesc =>
      'Manage your teaching periods, exams, holidays, and free days.';

  @override
  String get periods => 'Periods';

  @override
  String get loadTemplate => 'Load Template';

  @override
  String get clearCalendar => 'Clear Calendar';

  @override
  String get clearCalendarConfirm =>
      'Are you sure you want to delete all periods and events? This cannot be undone.';

  @override
  String get clearAll => 'Clear All';

  @override
  String get addPeriod => 'Add Period';

  @override
  String get noPeriodsAdded => 'No periods added yet.';

  @override
  String get holidaysFreeDays => 'Holidays & Free Days';

  @override
  String get addEvent => 'Add Event';

  @override
  String get noEventsAdded => 'No events added yet.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDesc =>
      'Stay updated with your schedule and deadlines.';

  @override
  String get lectureReminders => 'Lecture Reminders';

  @override
  String get lectureRemindersDesc => 'Get notified before your classes start.';

  @override
  String get taskDeadlines => 'Task Deadlines';

  @override
  String get taskDeadlinesDesc => 'Stay on top of your assignments and exams.';

  @override
  String get appUpdates => 'App Updates';

  @override
  String get appUpdatesDesc =>
      'Receive news about new features and improvements.';

  @override
  String get syncCloud => 'Sync & Cloud';

  @override
  String get syncCloudDesc =>
      'Your academic data is secured and synchronized via Classlly Cloud.';

  @override
  String get cloudSyncTitle => 'Classlly Cloud Sync';

  @override
  String lastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNow => 'Sync Now';

  @override
  String get never => 'Never';

  @override
  String get supabaseSecurity =>
      'Supabase ensures your data is encrypted and only accessible by you using Row Level Security (RLS). Google Drive and iCloud backups can be enabled in our web dashboard.';

  @override
  String get workspace => 'Workspace';

  @override
  String get close => 'Close';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get academicDetails => 'Academic Details';

  @override
  String get logOut => 'Log Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get studyHrs => 'Study Hrs';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinClasslly => 'Join Classlly to sync your notes across devices.';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signIn => 'Sign In';

  @override
  String get onboardingTitle1 => 'Welcome to Classlly';

  @override
  String get onboardingDesc1 =>
      'The ultimate student companion for organizing your academic life.';

  @override
  String get onboardingTitle2 => 'Smart Note Taking';

  @override
  String get onboardingDesc2 =>
      'Capture ideas with advanced tools, audio recording, and AI assistance.';

  @override
  String get onboardingTitle3 => 'Stay Organized';

  @override
  String get onboardingDesc3 =>
      'Track your courses, tasks, grades, and attendance in one place.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get createNewNote => 'Create New Note';

  @override
  String get noteTitle => 'Note Title';

  @override
  String get noteType => 'Note Type';

  @override
  String get drawing => 'Drawing';

  @override
  String get text => 'Text';

  @override
  String get create => 'Create';

  @override
  String get courseOptional => 'Course (Optional)';

  @override
  String get editTask => 'Edit Task';

  @override
  String get newTask => 'New Task';

  @override
  String get taskName => 'Task Name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get schedule => 'Schedule';

  @override
  String get dueDate => 'Due Date';

  @override
  String get reminder => 'Reminder';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createTask => 'Create Task';

  @override
  String get type => 'Type';

  @override
  String get select => 'Select';

  @override
  String get assignment => 'Assignment';

  @override
  String get exam => 'Exam';

  @override
  String get reading => 'Reading';

  @override
  String get project => 'Project';

  @override
  String get personal => 'Personal';

  @override
  String get other => 'Other';

  @override
  String get oneHourBefore => '1 hour before';

  @override
  String get twoHoursBefore => '2 hours before';

  @override
  String get oneDayBefore => '1 day before';

  @override
  String get oneWeekBefore => '1 week before';

  @override
  String get editCourse => 'Edit Course';

  @override
  String get newCourse => 'New Course';

  @override
  String get courseTitle => 'Course Title';

  @override
  String get credits => 'Credits';

  @override
  String get semester => 'Semester';

  @override
  String get courseLectureDetails => 'Course / Lecture Details';

  @override
  String get professor => 'Professor';

  @override
  String get room => 'Room';

  @override
  String get frequency => 'Frequency';

  @override
  String get day => 'Day';

  @override
  String get time => 'Time';

  @override
  String get seminarDetails => 'Seminar Details';

  @override
  String get seminarTeacher => 'SEMINAR TEACHER';

  @override
  String get courseColor => 'Course Color';

  @override
  String get createCourse => 'Create Course';

  @override
  String get weekly => 'Weekly';

  @override
  String get biWeeklyOdd => 'Bi-Weekly (odd)';

  @override
  String get biWeeklyEven => 'Bi-Weekly (even)';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get editAttendance => 'Edit Attendance';

  @override
  String get markPresent => 'Mark Present';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get late => 'Late';

  @override
  String get excused => 'Excused';

  @override
  String get selectCourse => 'Select Course';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get fieldCannotBeEmpty => 'Field cannot be empty';

  @override
  String get university => 'University';

  @override
  String get majorCourse => 'Major / Course';

  @override
  String get currentYear => 'Current Year';

  @override
  String get studentIdOptional => 'Student ID (Optional)';

  @override
  String get updateAcademicInfo => 'Update Academic Info';

  @override
  String get academicDetailsSaved => 'Academic details saved';

  @override
  String get addPage => 'Add Page';

  @override
  String get outlinePages => 'OUTLINE & PAGES';

  @override
  String get pageTemplate => 'PAGE TEMPLATE';

  @override
  String get dotGrid => 'Dot Grid';

  @override
  String get squared => 'Squared';

  @override
  String get lined => 'Lined';

  @override
  String get cornell => 'Cornell';

  @override
  String get blank => 'Blank';

  @override
  String get backToLibrary => 'Back to Library';

  @override
  String get toggleSidebar => 'Toggle Sidebar';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get syncing => 'SYNCING...';

  @override
  String autoSavedAt(String time) {
    return 'AUTO-SAVED AT $time';
  }

  @override
  String get stylusOnlyMode => 'Stylus Only Mode';

  @override
  String get export => 'Export';

  @override
  String get pickColor => 'Pick a color';

  @override
  String get addDone => 'Add & Done';

  @override
  String get insertPdfPage => 'Insert PDF Page';

  @override
  String get deleteColor => 'Delete Color';

  @override
  String get removeColorFromPalette => 'Remove this color from your palette?';

  @override
  String get width => 'WIDTH';

  @override
  String get opacity => 'OPACITY';

  @override
  String get size => 'SIZE';

  @override
  String get pixel => 'Pixel';

  @override
  String get object => 'Object';

  @override
  String get addCourseFirst => 'Add a course first to log grades';

  @override
  String get todaysSchedule => 'Today\'s Schedule';

  @override
  String get noLecturesToday => 'No lectures today';

  @override
  String get relaxOrStudy => 'Time to relax or catch up on study!';

  @override
  String percentCompleted(int percent) {
    return '$percent% Completed';
  }

  @override
  String pendingCount(int count) {
    return '$count Pending';
  }

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String noteMetadata(String date, int count) {
    return '$date • $count strokes';
  }

  @override
  String get gradeHistory => 'Grade History';

  @override
  String get noGradesRecorded => 'No grades recorded';

  @override
  String gradeMetadata(String date, int percent) {
    return '$date • Weight: $percent%';
  }

  @override
  String weightPercent(Object percent) {
    return 'Weight: $percent%';
  }

  @override
  String get deleteGradeConfirm =>
      'Are you sure you want to delete this grade record?';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get noAttendanceRecords => 'No attendance records';

  @override
  String get deleteAttendanceConfirm =>
      'Are you sure you want to delete this attendance record?';

  @override
  String get overview => 'Overview';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get backToCourses => 'BACK TO COURSES';

  @override
  String get noInstructor => 'No Instructor';

  @override
  String get currentGrade => 'CURRENT GRADE';

  @override
  String get gradeTrend => 'Grade Trend';

  @override
  String get attendanceOverview => 'Attendance Overview';

  @override
  String get rate => 'Rate';

  @override
  String lastSessions(Object count) {
    return 'Last $count sessions';
  }

  @override
  String get startTakingNotes => 'Start taking notes for this course!';

  @override
  String get open => 'Open';

  @override
  String ects(Object count) {
    return '$count ECTS';
  }

  @override
  String get lectureCourse => 'LECTURE / COURSE';

  @override
  String get instructor => 'INSTRUCTOR';

  @override
  String get notAssigned => 'Not Assigned';

  @override
  String get tbd => 'TBD';

  @override
  String get roomLocation => 'ROOM / LOCATION';

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String dueCount(Object count) {
    return '$count DUE';
  }

  @override
  String get noAssignments => 'No assignments';

  @override
  String get assignmentTitle => 'Assignment Title';

  @override
  String get gradePercent => 'Grade (%)';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteGrade => 'Delete Grade';
}
