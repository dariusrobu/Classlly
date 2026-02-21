import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/core/services/notification_service.dart';
import 'package:classlly/core/services/widget_service.dart';

class TaskProvider with ChangeNotifier {
  final NotesRepository _localRepository;
  final NotificationService _notificationService;
  final WidgetService _widgetService;

  TaskProvider({
    NotesRepository? repository,
    NotificationService? notificationService,
    WidgetService? widgetService,
  }) : _localRepository = repository ?? NotesRepository(),
       _notificationService = notificationService ?? NotificationService(),
       _widgetService = widgetService ?? WidgetService();

  List<Task> get tasks => _localRepository.getAllTasks();
  List<Task> get deletedTasks => _localRepository.getDeletedTasks();

  Future<void> saveTask(Task task) async {
    await _notificationService.requestPermissions();
    await _localRepository.saveTask(task);
    _scheduleTaskReminders(task);

    // Update widget
    await _widgetService.refreshUpNextWidget();

    notifyListeners();
  }

  void _scheduleTaskReminders(Task task) {
    // Cancel existing reminders for this task (using base ID logic)
    _notificationService.cancelNotification(task.id.hashCode * 10 + 1);

    if (task.isCompleted || task.isDeleted || task.dueDate == null) return;

    if (task.dueDate!.isAfter(DateTime.now())) {
      final date = task.dueDate!;
      final scheduled6AM = DateTime(date.year, date.month, date.day, 6, 0);

      _notificationService.scheduleTaskReminder(
        taskId: task.id.hashCode,
        title: task.title,
        dueDate: scheduled6AM,
      );
    }
  }

  Future<void> addTask(
    String title, {
    DateTime? dueDate,
    String? category,
  }) async {
    final task = Task.create(
      title: title,
      dueDate: dueDate,
      category: category,
      priority: category == 'Exam' ? 2 : 1,
    );
    await saveTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    final task = _localRepository.getTask(taskId);
    if (task != null) {
      task.isDeleted = true;
      await _localRepository.saveTask(task);
      await _widgetService.refreshUpNextWidget();
      notifyListeners();
    }
  }

  Future<void> restoreTask(String taskId) async {
    final task = _localRepository.getTask(taskId);
    if (task != null) {
      task.isDeleted = false;
      await _localRepository.saveTask(task);
      await _widgetService.refreshUpNextWidget();
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteTask(String taskId) async {
    _notificationService.cancelNotification(taskId.hashCode);
    await _localRepository.deleteTask(taskId);
    await _widgetService.refreshUpNextWidget();
    notifyListeners();
  }

  Future<void> toggleTask(Task task) async {
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) {
      _notificationService.cancelNotification(task.id.hashCode);
    } else {
      _scheduleTaskReminders(task);
    }
    await _localRepository.saveTask(task);

    await _widgetService.refreshUpNextWidget();

    notifyListeners();
  }
}
