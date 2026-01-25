import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

class AcademicCalendarProvider with ChangeNotifier {
  final NotesRepository _repository = NotesRepository();

  List<AcademicPeriod> _periods = [];
  List<AcademicEvent> _events = [];

  List<AcademicPeriod> get periods => _periods;
  List<AcademicEvent> get events => _events;

  AcademicCalendarProvider() {
    _loadData();
  }

  void _loadData() {
    _periods = _repository.getAllPeriods();
    _events = _repository.getAllEvents();
    notifyListeners();
  }

  Future<void> loadTemplate(Map<String, dynamic> calendarData) async {
    try {
      debugPrint('Loading template: ${calendarData['universityName']}');
      // Clear existing calendar data before loading a new one
      await clearCalendar();

      final List<dynamic> eventsData = calendarData['events'];
      debugPrint('Template has ${eventsData.length} events/periods.');

      for (var event in eventsData) {
        final String typeStr = event['type'];
        final String name = event['name'];
        final DateTime start = DateTime.parse(event['start']);
        final DateTime end = DateTime.parse(event['end']);

        if (typeStr == 'break') {
          debugPrint('Adding break as holiday period: $name');
          await addPeriod(
            name: name,
            startDate: start,
            endDate: end,
            type: AcademicPeriodType.holiday,
          );
        } else {
          // Map other types to AcademicPeriod
          AcademicPeriodType? periodType;
          switch (typeStr) {
            case 'teaching':
              periodType = AcademicPeriodType.teaching;
              break;
            case 'exam':
              periodType = AcademicPeriodType.exam;
              break;
            case 'retake':
              periodType = AcademicPeriodType.retake;
              break;
            case 'session':
              periodType = AcademicPeriodType.session;
              break;
          }

          if (periodType != null) {
            debugPrint('Adding period: $name ($typeStr)');
            await addPeriod(
              name: name,
              startDate: start,
              endDate: end,
              type: periodType,
            );
          }
        }
      }
      debugPrint('Template loaded successfully.');
    } catch (e, stack) {
      debugPrint('Error loading template: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> clearCalendar() async {
    final allPeriods = _repository.getAllPeriods();
    for (var period in allPeriods) {
      await _repository.deletePeriod(period.id);
    }
    final allEvents = _repository.getAllEvents();
    for (var event in allEvents) {
      await _repository.deleteEvent(event.id);
    }
    _loadData();
  }

  Future<List<dynamic>> getAvailableTemplates() async {
    try {
      debugPrint(
        'Fetching templates from assets/data/academic_calendars.json...',
      );
      final String content = await rootBundle.loadString(
        'assets/data/academic_calendars.json',
      );
      final data = jsonDecode(content);
      final calendars = data['calendars'] as List<dynamic>;
      debugPrint('Found ${calendars.length} templates.');
      return calendars;
    } catch (e, stack) {
      debugPrint('Error loading templates from assets: $e');
      debugPrint(stack.toString());
    }
    return [];
  }

  Future<void> addPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required AcademicPeriodType type,
  }) async {
    final period = AcademicPeriod.create(
      name: name,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
    await _repository.savePeriod(period);
    _loadData();
  }

  Future<void> updatePeriod(AcademicPeriod period) async {
    await _repository.savePeriod(period);
    _loadData();
  }

  Future<void> deletePeriod(String id) async {
    await _repository.deletePeriod(id);
    _loadData();
  }

  Future<void> addEvent({
    required String name,
    required DateTime date,
    required AcademicEventType type,
  }) async {
    final event = AcademicEvent.create(name: name, date: date, type: type);
    await _repository.saveEvent(event);
    _loadData();
  }

  Future<void> updateEvent(AcademicEvent event) async {
    await _repository.saveEvent(event);
    _loadData();
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
    _loadData();
  }

  // --- Week Calculation Logic ---

  /// Returns the week number (1-based) and whether it's odd or even for a given date.
  /// Returns null if the date is not within a teaching period.
  Map<String, dynamic>? getWeekInfo(DateTime date) {
    // Normalize date to remove time for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    AcademicPeriod? currentPeriod;
    for (var period in _periods) {
      if (period.type == AcademicPeriodType.teaching) {
        final start = DateTime(
          period.startDate.year,
          period.startDate.month,
          period.startDate.day,
        );
        final end = DateTime(
          period.endDate.year,
          period.endDate.month,
          period.endDate.day,
        );

        if (normalizedDate.isAtSameMomentAs(start) ||
            normalizedDate.isAtSameMomentAs(end) ||
            (normalizedDate.isAfter(start) && normalizedDate.isBefore(end))) {
          currentPeriod = period;
          break;
        }
      }
    }

    if (currentPeriod == null) return null;

    // Find the "Semester Start" for this period.
    // We look for the earliest teaching period that is within 20 weeks of this one.
    DateTime semStart = currentPeriod.startDate;
    for (var p in _periods) {
      if (p.type == AcademicPeriodType.teaching) {
        if (p.startDate.isBefore(semStart) &&
            currentPeriod.startDate.difference(p.startDate).inDays < 140) {
          semStart = p.startDate;
        }
      }
    }

    // Align the reference start to the Monday of that week.
    // In Dart, weekday is 1 (Mon) to 7 (Sun).
    final referenceMonday = DateTime(
      semStart.year,
      semStart.month,
      semStart.day,
    ).subtract(Duration(days: semStart.weekday - 1));

    // Calculate difference in days from the reference Monday
    final diffDays = normalizedDate.difference(referenceMonday).inDays;

    // Calculate week number (1-based)
    final weekNum = (diffDays / 7).floor() + 1;
    final isOdd = weekNum % 2 != 0;

    return {
      'week': weekNum,
      'isOdd': isOdd,
      'label': isOdd ? 'Odd' : 'Even',
      'periodName': currentPeriod.name,
    };
  }
}
