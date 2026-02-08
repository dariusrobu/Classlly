import 'dart:math';
import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/student_profile_model.dart';
import 'package:classlly/data/models/course_model.dart';
import 'package:classlly/data/models/attendance_model.dart';
import 'package:classlly/data/models/grade_model.dart';
import 'package:classlly/data/models/task_model.dart';

class ProfileProvider with ChangeNotifier {
  final NotesRepository _localRepository;

  ProfileProvider({NotesRepository? repository})
    : _localRepository = repository ?? NotesRepository();

  StudentProfile get studentProfile => _localRepository.getStudentProfile();

  void refreshProfile() {
    notifyListeners();
  }

  Future<void> createDemoProfile() async {
    // Safety check: Ensure profile is set to Guest
    await _localRepository.saveStudentProfile(
      StudentProfile(
        name: 'Guest Student',
        university: 'Demo University',
        major: 'Computer Science',
        year: 'Sophomore',
        studentId: 'DEMO-123',
      ),
    );

    final random = Random();
    var createdCourses = _localRepository.getAllCourses();
    
    // Safety Force Clear if needed (though signOut should have handled it)
    if (createdCourses.isNotEmpty) {
      // If we are here, something weird happened or re-running demo setup.
      // We'll just continue or could clear. Let's trust signOut cleared it, 
      // but if not, let's at least ensure we don't duplicate if exactly same.
      // For now, we assume clean slate.
    }

    if (createdCourses.isEmpty) {
      final coursesData = [
        {
          'title': 'Computer Science 101',
          'professor': 'Dr. Alan Turing',
          'location': 'Lab 3B',
          'day': 'Monday',
          'time': '10:00 AM',
          'color': const Color(0xFF3B82F6),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Ada Lovelace',
          'seminarLoc': 'Room 202',
          'seminarDay': 'Wednesday',
          'seminarTime': '02:00 PM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'Calculus II',
          'professor': 'Prof. Isaac Newton',
          'location': 'Room 204',
          'day': 'Tuesday',
          'time': '02:00 PM',
          'color': const Color(0xFFEF4444),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Gottfried Leibniz',
          'seminarLoc': 'Room 301',
          'seminarDay': 'Thursday',
          'seminarTime': '04:00 PM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'Physics: Mechanics',
          'professor': 'Dr. Marie Curie',
          'location': 'Hall A',
          'day': 'Wednesday',
          'time': '09:00 AM',
          'color': const Color(0xFF10B981),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Albert Einstein',
          'seminarLoc': 'Lab 1',
          'seminarDay': 'Friday',
          'seminarTime': '10:00 AM',
          'seminarFreq': 'Bi-Weekly (odd)',
        },
        {
          'title': 'English Literature',
          'professor': 'Prof. Shakespeare',
          'location': 'Library 1',
          'day': 'Thursday',
          'time': '11:00 AM',
          'color': const Color(0xFFF59E0B),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Jane Austen',
          'seminarLoc': 'Reading Room',
          'seminarDay': 'Monday',
          'seminarTime': '01:00 PM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'World History',
          'professor': 'Dr. Herodotus',
          'location': 'Room 105',
          'day': 'Friday',
          'time': '01:00 PM',
          'color': const Color(0xFF8B5CF6),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Cleopatra',
          'seminarLoc': 'History Annex',
          'seminarDay': 'Tuesday',
          'seminarTime': '09:00 AM',
          'seminarFreq': 'Bi-Weekly (even)',
        },
        {
          'title': 'Biology 101',
          'professor': 'Dr. Darwin',
          'location': 'Bio Lab',
          'day': 'Monday',
          'time': '02:00 PM',
          'color': const Color(0xFF4ADE80),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Mendel',
          'seminarLoc': 'Greenhouse',
          'seminarDay': 'Wednesday',
          'seminarTime': '10:00 AM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'Chemistry',
          'professor': 'Dr. Mendeleev',
          'location': 'Chem Lab',
          'day': 'Tuesday',
          'time': '10:00 AM',
          'color': const Color(0xFF06B6D4),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Nobel',
          'seminarLoc': 'Lab 4',
          'seminarDay': 'Thursday',
          'seminarTime': '02:00 PM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'Economics',
          'professor': 'Dr. Smith',
          'location': 'Lecture Hall 2',
          'day': 'Wednesday',
          'time': '04:00 PM',
          'color': const Color(0xFFF472B6),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Keynes',
          'seminarLoc': 'Room 101',
          'seminarDay': 'Friday',
          'seminarTime': '02:00 PM',
          'seminarFreq': 'Weekly',
        },
        {
          'title': 'Psychology',
          'professor': 'Dr. Freud',
          'location': 'Room 305',
          'day': 'Thursday',
          'time': '09:00 AM',
          'color': const Color(0xFFA855F7),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Jung',
          'seminarLoc': 'Clinic A',
          'seminarDay': 'Monday',
          'seminarTime': '04:00 PM',
          'seminarFreq': 'Bi-Weekly (odd)',
        },
        {
          'title': 'Art History',
          'professor': 'Prof. Da Vinci',
          'location': 'Gallery 1',
          'day': 'Friday',
          'time': '11:00 AM',
          'color': const Color(0xFFFB923C),
          'frequency': 'Weekly',
          'seminarProf': 'T.A. Michelangelo',
          'seminarLoc': 'Studio 2',
          'seminarDay': 'Tuesday',
          'seminarTime': '11:00 AM',
          'seminarFreq': 'Weekly',
        },
      ];

      for (var data in coursesData) {
        final course = Course.create(
          title: data['title'] as String,
          professor: data['professor'] as String,
          location: data['location'] as String,
          courseDay: data['day'] as String,
          courseTime: data['time'] as String,
          color: data['color'] as Color,
          semester: 'Semester 1',
          credits: 6.0,
          courseFrequency: data['frequency'] as String,
          seminarProfessor: data['seminarProf'] as String,
          seminarLocation: data['seminarLoc'] as String,
          seminarDay: data['seminarDay'] as String,
          seminarTime: data['seminarTime'] as String,
          seminarFrequency: data['seminarFreq'] as String,
        );
        await _localRepository.saveCourse(course);
        createdCourses.add(course);
      }
    }

    // Attendance Records
    for (var course in createdCourses) {
      final existingAttendance = _localRepository.getAttendanceForCourse(
        course.id,
      );
      for (var a in existingAttendance) {
        await _localRepository.deleteAttendance(a.id);
      }

      for (int i = 0; i < 10; i++) {
        final r = random.nextDouble();
        AttendanceStatus status;
        if (r < 0.85) {
          status = AttendanceStatus.present;
        } else if (r < 0.95) {
          status = AttendanceStatus.absent;
        } else {
          status = AttendanceStatus.excused;
        }

        final date = DateTime.now().subtract(Duration(days: i * 7));
        final attendance = Attendance.create(
          courseId: course.id,
          date: date,
          status: status,
        );
        await _localRepository.saveAttendance(attendance);
      }
    }

    // Grades
    final assignmentTypes = [
      'Quiz',
      'Homework',
      'Lab Report',
      'Midterm',
      'Project',
      'Essay',
      'Final',
      'Presentation',
    ];
    for (var course in createdCourses) {
      final existingGrades = _localRepository.getGradesForCourse(course.id);
      for (var g in existingGrades) {
        await _localRepository.deleteGrade(g.id);
      }

      for (int i = 0; i < 5; i++) {
        final type = assignmentTypes[i % assignmentTypes.length];
        final score = 65 + random.nextDouble() * 35;
        final grade = Grade.create(
          courseId: course.id,
          title: '$type ${i + 1}',
          score: double.parse(score.toStringAsPrecision(4)),
          maxScore: 100,
          weight: (type == 'Midterm' || type == 'Project' || type == 'Final')
              ? 0.25
              : 0.05,
          date: DateTime.now().subtract(Duration(days: random.nextInt(90))),
        );
        await _localRepository.saveGrade(grade);
      }
    }

    // Tasks
    final taskTemplates = [
      'Read Chapter',
      'Submit Assignment',
      'Prepare for Quiz',
      'Group Project Meeting',
      'Research Paper Draft',
      'Review Lecture Notes',
      'Watch Video Lecture',
      'Complete Practice Problems',
    ];
    for (var course in createdCourses) {
      for (int k = 0; k < 4; k++) {
        final template = taskTemplates[random.nextInt(taskTemplates.length)];
        final isUrgent = random.nextDouble() < 0.3;
        final isDone = random.nextDouble() < 0.4;
        await _localRepository.saveTask(
          Task.create(
              title: '$template for ${course.title}',
              courseId: course.id,
              dueDate: DateTime.now().add(
                Duration(days: random.nextInt(21) - 7),
              ),
              category: 'Study',
              priority: isUrgent ? 2 : 1,
              description:
                  'Complete the $template for ${course.title}. Ensure all requirements are met.',
            )
            ..isCompleted = isDone
            ..progress = isDone ? 1.0 : (random.nextDouble() * 0.8),
        );
      }
    }

    // Personal Tasks
    final personalTasks = [
      'Buy Groceries',
      'Gym Session',
      'Call Mom',
      'Pay Bills',
      'Laundry',
      'Clean Room',
      'Doctor Appointment',
      'Buy Birthday Gift',
      'Update Resume',
      'Apply for Internships',
    ];
    for (var title in personalTasks) {
      await _localRepository.saveTask(
        Task.create(
          title: title,
          category: 'Personal',
          priority: random.nextInt(3),
          dueDate: DateTime.now().add(Duration(days: random.nextInt(14))),
        ),
      );
    }

    notifyListeners();
  }
}
