import 'package:flutter/material.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/task_model.dart';
import 'package:classlly/core/services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final NotesRepository _localRepository;
  final NotificationService _notificationService;

  TaskProvider({NotesRepository? repository, NotificationService? notificationService})
      : _localRepository = repository ?? NotesRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<Task> get tasks => _localRepository.getAllTasks();
  List<Task> get deletedTasks => _localRepository.getDeletedTasks();

  Future<void> saveTask(Task task) async {
    await _notificationService.requestPermissions();
    await _localRepository.saveTask(task);
    _scheduleTaskReminders(task);
    notifyListeners();
  }

  void _scheduleTaskReminders(Task task) {
    final notificationId = task.id.hashCode;
    _notificationService.cancelNotification(notificationId);

    if (task.isCompleted || task.isDeleted) return;

    if (task.reminderTime != null &&
        task.reminderTime!.isAfter(DateTime.now())) {
      _notificationService.scheduleNotification(
        id: notificationId,
        title: 'Task Reminder',
        body: 'Reminder: ${task.title}',
        scheduledDate: task.reminderTime!,
        payload: 'task_${task.id}',
      );
    } else if (task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
      final reminder = task.dueDate!.subtract(const Duration(hours: 1));
      if (reminder.isAfter(DateTime.now())) {
        _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Upcoming Deadline',
          body: 'Your task "${task.title}" is due in 1 hour.',
          scheduledDate: reminder,
          payload: 'task_${task.id}',
        );
      }
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
      notifyListeners();
    }
  }

  Future<void> restoreTask(String taskId) async {
    final task = _localRepository.getTask(taskId);
    if (task != null) {
      task.isDeleted = false;
      await _localRepository.saveTask(task);
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteTask(String taskId) async {
    _notificationService.cancelNotification(taskId.hashCode);
    await _localRepository.deleteTask(taskId);
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
    notifyListeners();
  }
}
