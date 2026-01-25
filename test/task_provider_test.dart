import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:classlly/features/library/providers/task_provider.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/core/services/notification_service.dart';
import 'package:classlly/data/models/task_model.dart';

class MockNotesRepository extends Mock implements NotesRepository {}
class MockNotificationService extends Mock implements NotificationService {}
class TaskFake extends Fake implements Task {}

void main() {
  setUpAll(() {
    registerFallbackValue(TaskFake());
  });

  late TaskProvider taskProvider;
  late MockNotesRepository mockRepository;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockRepository = MockNotesRepository();
    mockNotificationService = MockNotificationService();
    taskProvider = TaskProvider(
      repository: mockRepository,
      notificationService: mockNotificationService,
    );
  });

  group('TaskProvider', () {
    test('toggleTask updates completion status and handles notifications', () async {
      final task = Task.create(title: 'Test Task');
      task.isCompleted = false;

      when(() => mockRepository.saveTask(any())).thenAnswer((_) async {});
      when(() => mockNotificationService.cancelNotification(any())).thenAnswer((_) async {});

      // Toggle to completed
      await taskProvider.toggleTask(task);
      expect(task.isCompleted, true);
      verify(() => mockNotificationService.cancelNotification(task.id.hashCode)).called(1);

      // Toggle back to incomplete
      when(() => mockNotificationService.requestPermissions()).thenAnswer((_) async => true);
      when(() => mockNotificationService.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        payload: any(named: 'payload'),
      )).thenAnswer((_) async {});

      await taskProvider.toggleTask(task);
      expect(task.isCompleted, false);
      
      // Verify total calls to saveTask
      verify(() => mockRepository.saveTask(task)).called(2);
    });

    test('deleteTask marks task as deleted', () async {
      final task = Task.create(title: 'Delete Me');
      when(() => mockRepository.getTask(task.id)).thenReturn(task);
      when(() => mockRepository.saveTask(any())).thenAnswer((_) async {});

      await taskProvider.deleteTask(task.id);

      expect(task.isDeleted, true);
      verify(() => mockRepository.saveTask(task)).called(1);
    });
  });
}
