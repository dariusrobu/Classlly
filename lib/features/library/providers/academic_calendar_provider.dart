import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classlly/data/models/academic_calendar_model.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/core/services/supabase_cloud_service.dart';

class AcademicCalendarProvider with ChangeNotifier {
  final NotesRepository _repository;
  final NotificationService _notificationService;
  final CloudStorageService _cloudService;
  static const String _vercelBaseUrl = 'https://classlly-server.vercel.app';

  List<AcademicPeriod> _periods = [];
  List<AcademicEvent> _events = [];

  List<AcademicPeriod> get periods => _periods;
  List<AcademicEvent> get events => _events;

  AcademicCalendarProvider({
    NotesRepository? repository,
    NotificationService? notificationService,
    CloudStorageService? cloudService,
  }) : _repository = repository ?? NotesRepository(),
       _notificationService = notificationService ?? NotificationService(),
       _cloudService = cloudService ?? SupabaseCloudService() {
    Future.microtask(() => _loadData());
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
      _cloudService.syncCalendar();
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
      await deleteEvent(event.id);
    }
    await _cloudService.syncCalendar();
    _loadData();
  }

  Future<List<dynamic>> getAvailableTemplates() async {
    // 1. Try Vercel Remote Fetch
    try {
      debugPrint('Fetching templates from Vercel: $_vercelBaseUrl/api/calendars');
      final response = await http.get(
        Uri.parse('$_vercelBaseUrl/api/calendars'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final calendars = data['calendars'] as List<dynamic>;
        debugPrint('Successfully fetched ${calendars.length} templates from Vercel.');
        return calendars;
      } else {
        debugPrint('Vercel fetch failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching from Vercel: $e. Falling back to local assets.');
    }

    // 2. Fallback to Local Assets
    try {
      debugPrint('Loading templates from local assets (fallback)...');
      // Fix: path was calendars.json, correct is academic_calendars.json
      final String response = await rootBundle.loadString('assets/data/academic_calendars.json');
      final data = jsonDecode(response);
      final calendars = data['calendars'] as List<dynamic>;
      debugPrint('Found ${calendars.length} templates locally.');
      return calendars;
    } catch (e) {
      debugPrint('Error fetching templates from local assets: $e');
      return []; // Return empty list instead of rethrowing to prevent crash
    }
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
    _cloudService.syncCalendar();
    _loadData();
  }

  Future<void> updatePeriod(AcademicPeriod period) async {
    await _repository.savePeriod(period);
    _cloudService.syncCalendar();
    _loadData();
  }

  Future<void> deletePeriod(String id) async {
    await _repository.deletePeriod(id);
    _cloudService.syncCalendar();
    _loadData();
  }

  void _scheduleEventReminder(AcademicEvent event) {
    if (event.date.isBefore(DateTime.now())) return;

    // Explicit 6:00 AM override
    final scheduledDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      6,
      0,
    );

    _notificationService.scheduleEventReminder(
      eventId: event.id,
      title: event.name,
      eventDate: scheduledDate,
    );
  }

  void _cancelEventReminder(String eventId) {
    _notificationService.cancelNotification(eventId.hashCode);
  }

  Future<void> addEvent({
    required String name,
    required DateTime date,
    required AcademicEventType type,
  }) async {
    await _notificationService.requestPermissions();
    final event = AcademicEvent.create(name: name, date: date, type: type);
    await _repository.saveEvent(event);
    _scheduleEventReminder(event);
    _cloudService.syncCalendar();
    _loadData();
  }

  Future<void> updateEvent(AcademicEvent event) async {
    await _notificationService.requestPermissions();
    await _repository.saveEvent(event);
    _cancelEventReminder(event.id);
    _scheduleEventReminder(event);
    _cloudService.syncCalendar();
    _loadData();
  }

  Future<void> deleteEvent(String id) async {
    _cancelEventReminder(id);
    await _repository.deleteEvent(id);
    _cloudService.syncCalendar();
    _loadData();
  }

  // --- Week Calculation Logic ---

  /// Returns the week number (1-based) and whether it's odd or even for a given date.
  /// Returns period info for any academic period type.
  /// Week numbers are only calculated for teaching periods.
  Map<String, dynamic>? getWeekInfo(DateTime date) {
    // Normalize date to remove time for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    AcademicPeriod? currentPeriod;
    for (var period in _periods) {
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

    if (currentPeriod == null) return null;

    // For non-teaching periods, return just the period name
    if (currentPeriod.type != AcademicPeriodType.teaching) {
      return {
        'week': null,
        'isOdd': null,
        'label': currentPeriod.name,
        'periodName': currentPeriod.name,
        'periodType': currentPeriod.type.toString().split('.').last,
      };
    }

    // For teaching periods, calculate week number
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
      'periodType': 'teaching',
    };
  }
}
