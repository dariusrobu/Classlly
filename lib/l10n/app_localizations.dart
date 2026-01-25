import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Classlly'**
  String get appTitle;

  /// Welcome message on dashboard
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// No description provided for @dailyAgenda.
  ///
  /// In en, this message translates to:
  /// **'Daily Agenda'**
  String get dailyAgenda;

  /// No description provided for @dailyAgendaBody.
  ///
  /// In en, this message translates to:
  /// **'Check your tasks and schedule for today.'**
  String get dailyAgendaBody;

  /// No description provided for @performanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get performanceOverview;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @addGrade.
  ///
  /// In en, this message translates to:
  /// **'Add Grade'**
  String get addGrade;

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get markAttendance;

  /// No description provided for @taskDashboard.
  ///
  /// In en, this message translates to:
  /// **'Task Dashboard'**
  String get taskDashboard;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'You have {count} tasks in total.'**
  String totalTasks(int count);

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get todo;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @clearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clear Completed'**
  String get clearCompleted;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @freeDay.
  ///
  /// In en, this message translates to:
  /// **'Free day!'**
  String get freeDay;

  /// No description provided for @noTasksScheduled.
  ///
  /// In en, this message translates to:
  /// **'You have no tasks scheduled for today.'**
  String get noTasksScheduled;

  /// No description provided for @nothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get nothingScheduled;

  /// No description provided for @timelineClear.
  ///
  /// In en, this message translates to:
  /// **'Your timeline is clear for this day.'**
  String get timelineClear;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @academicScheduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your academic schedule and deadlines.'**
  String get academicScheduleDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get allDay;

  /// No description provided for @lecture.
  ///
  /// In en, this message translates to:
  /// **'Lecture'**
  String get lecture;

  /// No description provided for @seminar.
  ///
  /// In en, this message translates to:
  /// **'SEMINAR'**
  String get seminar;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize how Classlly looks and feels on your device.'**
  String get appearanceDesc;

  /// No description provided for @interfaceTheme.
  ///
  /// In en, this message translates to:
  /// **'Interface Theme'**
  String get interfaceTheme;

  /// No description provided for @themeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose between light, dark, or system default.'**
  String get themeDesc;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the glowing accent used for buttons and highlights.'**
  String get accentColorDesc;

  /// No description provided for @academicCalendar.
  ///
  /// In en, this message translates to:
  /// **'Academic Calendar'**
  String get academicCalendar;

  /// No description provided for @calendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your teaching periods, exams, holidays, and free days.'**
  String get calendarDesc;

  /// No description provided for @periods.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get periods;

  /// No description provided for @loadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Load Template'**
  String get loadTemplate;

  /// No description provided for @clearCalendar.
  ///
  /// In en, this message translates to:
  /// **'Clear Calendar'**
  String get clearCalendar;

  /// No description provided for @clearCalendarConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all periods and events? This cannot be undone.'**
  String get clearCalendarConfirm;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @addPeriod.
  ///
  /// In en, this message translates to:
  /// **'Add Period'**
  String get addPeriod;

  /// No description provided for @noPeriodsAdded.
  ///
  /// In en, this message translates to:
  /// **'No periods added yet.'**
  String get noPeriodsAdded;

  /// No description provided for @holidaysFreeDays.
  ///
  /// In en, this message translates to:
  /// **'Holidays & Free Days'**
  String get holidaysFreeDays;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @noEventsAdded.
  ///
  /// In en, this message translates to:
  /// **'No events added yet.'**
  String get noEventsAdded;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with your schedule and deadlines.'**
  String get notificationsDesc;

  /// No description provided for @lectureReminders.
  ///
  /// In en, this message translates to:
  /// **'Lecture Reminders'**
  String get lectureReminders;

  /// No description provided for @lectureRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified before your classes start.'**
  String get lectureRemindersDesc;

  /// No description provided for @taskDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Task Deadlines'**
  String get taskDeadlines;

  /// No description provided for @taskDeadlinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of your assignments and exams.'**
  String get taskDeadlinesDesc;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get appUpdates;

  /// No description provided for @appUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive news about new features and improvements.'**
  String get appUpdatesDesc;

  /// No description provided for @syncCloud.
  ///
  /// In en, this message translates to:
  /// **'Sync & Cloud'**
  String get syncCloud;

  /// No description provided for @syncCloudDesc.
  ///
  /// In en, this message translates to:
  /// **'Your academic data is secured and synchronized via Classlly Cloud.'**
  String get syncCloudDesc;

  /// No description provided for @cloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Classlly Cloud Sync'**
  String get cloudSyncTitle;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String lastSynced(String time);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @supabaseSecurity.
  ///
  /// In en, this message translates to:
  /// **'Supabase ensures your data is encrypted and only accessible by you using Row Level Security (RLS). Google Drive and iCloud backups can be enabled in our web dashboard.'**
  String get supabaseSecurity;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @academicDetails.
  ///
  /// In en, this message translates to:
  /// **'Academic Details'**
  String get academicDetails;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @studyHrs.
  ///
  /// In en, this message translates to:
  /// **'Study Hrs'**
  String get studyHrs;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinClasslly.
  ///
  /// In en, this message translates to:
  /// **'Join Classlly to sync your notes across devices.'**
  String get joinClasslly;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Classlly'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'The ultimate student companion for organizing your academic life.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Note Taking'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Capture ideas with advanced tools, audio recording, and AI assistance.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay Organized'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Track your courses, tasks, grades, and attendance in one place.'**
  String get onboardingDesc3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @createNewNote.
  ///
  /// In en, this message translates to:
  /// **'Create New Note'**
  String get createNewNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Title'**
  String get noteTitle;

  /// No description provided for @noteType.
  ///
  /// In en, this message translates to:
  /// **'Note Type'**
  String get noteType;

  /// No description provided for @drawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get drawing;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @courseOptional.
  ///
  /// In en, this message translates to:
  /// **'Course (Optional)'**
  String get courseOptional;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @exam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exam;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @oneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get oneHourBefore;

  /// No description provided for @twoHoursBefore.
  ///
  /// In en, this message translates to:
  /// **'2 hours before'**
  String get twoHoursBefore;

  /// No description provided for @oneDayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get oneDayBefore;

  /// No description provided for @oneWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'1 week before'**
  String get oneWeekBefore;

  /// No description provided for @editCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit Course'**
  String get editCourse;

  /// No description provided for @newCourse.
  ///
  /// In en, this message translates to:
  /// **'New Course'**
  String get newCourse;

  /// No description provided for @courseTitle.
  ///
  /// In en, this message translates to:
  /// **'Course Title'**
  String get courseTitle;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @courseLectureDetails.
  ///
  /// In en, this message translates to:
  /// **'Course / Lecture Details'**
  String get courseLectureDetails;

  /// No description provided for @professor.
  ///
  /// In en, this message translates to:
  /// **'Professor'**
  String get professor;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @seminarDetails.
  ///
  /// In en, this message translates to:
  /// **'Seminar Details'**
  String get seminarDetails;

  /// No description provided for @seminarTeacher.
  ///
  /// In en, this message translates to:
  /// **'SEMINAR TEACHER'**
  String get seminarTeacher;

  /// No description provided for @courseColor.
  ///
  /// In en, this message translates to:
  /// **'Course Color'**
  String get courseColor;

  /// No description provided for @createCourse.
  ///
  /// In en, this message translates to:
  /// **'Create Course'**
  String get createCourse;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @biWeeklyOdd.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly (odd)'**
  String get biWeeklyOdd;

  /// No description provided for @biWeeklyEven.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly (even)'**
  String get biWeeklyEven;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @editAttendance.
  ///
  /// In en, this message translates to:
  /// **'Edit Attendance'**
  String get editAttendance;

  /// No description provided for @markPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark Present'**
  String get markPresent;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @excused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get excused;

  /// No description provided for @selectCourse.
  ///
  /// In en, this message translates to:
  /// **'Select Course'**
  String get selectCourse;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @fieldCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Field cannot be empty'**
  String get fieldCannotBeEmpty;

  /// No description provided for @university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get university;

  /// No description provided for @majorCourse.
  ///
  /// In en, this message translates to:
  /// **'Major / Course'**
  String get majorCourse;

  /// No description provided for @currentYear.
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get currentYear;

  /// No description provided for @studentIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Student ID (Optional)'**
  String get studentIdOptional;

  /// No description provided for @updateAcademicInfo.
  ///
  /// In en, this message translates to:
  /// **'Update Academic Info'**
  String get updateAcademicInfo;

  /// No description provided for @academicDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Academic details saved'**
  String get academicDetailsSaved;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add Page'**
  String get addPage;

  /// No description provided for @outlinePages.
  ///
  /// In en, this message translates to:
  /// **'OUTLINE & PAGES'**
  String get outlinePages;

  /// No description provided for @pageTemplate.
  ///
  /// In en, this message translates to:
  /// **'PAGE TEMPLATE'**
  String get pageTemplate;

  /// No description provided for @dotGrid.
  ///
  /// In en, this message translates to:
  /// **'Dot Grid'**
  String get dotGrid;

  /// No description provided for @squared.
  ///
  /// In en, this message translates to:
  /// **'Squared'**
  String get squared;

  /// No description provided for @lined.
  ///
  /// In en, this message translates to:
  /// **'Lined'**
  String get lined;

  /// No description provided for @cornell.
  ///
  /// In en, this message translates to:
  /// **'Cornell'**
  String get cornell;

  /// No description provided for @blank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get blank;

  /// No description provided for @backToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Back to Library'**
  String get backToLibrary;

  /// No description provided for @toggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get toggleSidebar;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'SYNCING...'**
  String get syncing;

  /// No description provided for @autoSavedAt.
  ///
  /// In en, this message translates to:
  /// **'AUTO-SAVED AT {time}'**
  String autoSavedAt(String time);

  /// No description provided for @stylusOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'Stylus Only Mode'**
  String get stylusOnlyMode;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

  /// No description provided for @addDone.
  ///
  /// In en, this message translates to:
  /// **'Add & Done'**
  String get addDone;

  /// No description provided for @insertPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Insert PDF Page'**
  String get insertPdfPage;

  /// No description provided for @deleteColor.
  ///
  /// In en, this message translates to:
  /// **'Delete Color'**
  String get deleteColor;

  /// No description provided for @removeColorFromPalette.
  ///
  /// In en, this message translates to:
  /// **'Remove this color from your palette?'**
  String get removeColorFromPalette;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'WIDTH'**
  String get width;

  /// No description provided for @opacity.
  ///
  /// In en, this message translates to:
  /// **'OPACITY'**
  String get opacity;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get size;

  /// No description provided for @pixel.
  ///
  /// In en, this message translates to:
  /// **'Pixel'**
  String get pixel;

  /// No description provided for @object.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get object;

  /// No description provided for @addCourseFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a course first to log grades'**
  String get addCourseFirst;

  /// No description provided for @todaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaysSchedule;

  /// No description provided for @noLecturesToday.
  ///
  /// In en, this message translates to:
  /// **'No lectures today'**
  String get noLecturesToday;

  /// No description provided for @relaxOrStudy.
  ///
  /// In en, this message translates to:
  /// **'Time to relax or catch up on study!'**
  String get relaxOrStudy;

  /// No description provided for @percentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Completed'**
  String percentCompleted(int percent);

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending'**
  String pendingCount(int count);

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noteMetadata.
  ///
  /// In en, this message translates to:
  /// **'{date} • {count} strokes'**
  String noteMetadata(String date, int count);

  /// No description provided for @gradeHistory.
  ///
  /// In en, this message translates to:
  /// **'Grade History'**
  String get gradeHistory;

  /// No description provided for @noGradesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No grades recorded'**
  String get noGradesRecorded;

  /// No description provided for @gradeMetadata.
  ///
  /// In en, this message translates to:
  /// **'{date} • Weight: {percent}%'**
  String gradeMetadata(String date, int percent);

  /// No description provided for @weightPercent.
  ///
  /// In en, this message translates to:
  /// **'Weight: {percent}%'**
  String weightPercent(Object percent);

  /// No description provided for @deleteGradeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this grade record?'**
  String get deleteGradeConfirm;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @noAttendanceRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get noAttendanceRecords;

  /// No description provided for @deleteAttendanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attendance record?'**
  String get deleteAttendanceConfirm;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @backToCourses.
  ///
  /// In en, this message translates to:
  /// **'BACK TO COURSES'**
  String get backToCourses;

  /// No description provided for @noInstructor.
  ///
  /// In en, this message translates to:
  /// **'No Instructor'**
  String get noInstructor;

  /// No description provided for @currentGrade.
  ///
  /// In en, this message translates to:
  /// **'CURRENT GRADE'**
  String get currentGrade;

  /// No description provided for @gradeTrend.
  ///
  /// In en, this message translates to:
  /// **'Grade Trend'**
  String get gradeTrend;

  /// No description provided for @attendanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Attendance Overview'**
  String get attendanceOverview;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @lastSessions.
  ///
  /// In en, this message translates to:
  /// **'Last {count} sessions'**
  String lastSessions(Object count);

  /// No description provided for @startTakingNotes.
  ///
  /// In en, this message translates to:
  /// **'Start taking notes for this course!'**
  String get startTakingNotes;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @ects.
  ///
  /// In en, this message translates to:
  /// **'{count} ECTS'**
  String ects(Object count);

  /// No description provided for @lectureCourse.
  ///
  /// In en, this message translates to:
  /// **'LECTURE / COURSE'**
  String get lectureCourse;

  /// No description provided for @instructor.
  ///
  /// In en, this message translates to:
  /// **'INSTRUCTOR'**
  String get instructor;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @roomLocation.
  ///
  /// In en, this message translates to:
  /// **'ROOM / LOCATION'**
  String get roomLocation;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @dueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} DUE'**
  String dueCount(Object count);

  /// No description provided for @noAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments'**
  String get noAssignments;

  /// No description provided for @assignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment Title'**
  String get assignmentTitle;

  /// No description provided for @gradePercent.
  ///
  /// In en, this message translates to:
  /// **'Grade (%)'**
  String get gradePercent;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteGrade.
  ///
  /// In en, this message translates to:
  /// **'Delete Grade'**
  String get deleteGrade;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @pleaseSelectCourse.
  ///
  /// In en, this message translates to:
  /// **'Please select a course'**
  String get pleaseSelectCourse;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get emptyTrash;

  /// No description provided for @trashEmptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied successfully'**
  String get trashEmptied;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @renameFolder.
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get renameFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get deleteFolder;

  /// No description provided for @deleteFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This will move it to the Trash.'**
  String deleteFolderConfirm(String title);

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to...'**
  String get moveTo;

  /// No description provided for @myNotesRoot.
  ///
  /// In en, this message translates to:
  /// **'My Notes (Root)'**
  String get myNotesRoot;

  /// No description provided for @moveNoteTo.
  ///
  /// In en, this message translates to:
  /// **'Move Note to...'**
  String get moveNoteTo;

  /// No description provided for @renameNote.
  ///
  /// In en, this message translates to:
  /// **'Rename Note'**
  String get renameNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This will move it to the Trash.'**
  String deleteNoteConfirm(String title);

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty Folder'**
  String get emptyFolder;

  /// No description provided for @organizeStudies.
  ///
  /// In en, this message translates to:
  /// **'Organize your studies by creating folders or starting a new note.'**
  String get organizeStudies;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @trashDesc.
  ///
  /// In en, this message translates to:
  /// **'Items here will be permanently deleted when you empty the trash.'**
  String get trashDesc;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all items in the trash? This action cannot be undone.'**
  String get emptyTrashConfirm;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @trashIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashIsEmpty;

  /// No description provided for @trashEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Deleted notes and tasks will appear here for 30 days before being permanently removed.'**
  String get trashEmptyDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
