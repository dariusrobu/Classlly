import 'package:flutter/foundation.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';
import 'sync_scheduler.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  late final OfflineQueueService offlineQueue;
  late final ConnectivityService connectivity;
  late final SyncScheduler scheduler;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    debugPrint('SYNC_MANAGER: Initializing...');

    offlineQueue = OfflineQueueService();
    await offlineQueue.init();

    connectivity = ConnectivityService();
    await connectivity.init();

    scheduler = SyncScheduler(
      queueService: offlineQueue,
      connectivityService: connectivity,
    );
    scheduler.start();

    _isInitialized = true;
    debugPrint('SYNC_MANAGER: Initialized successfully');
  }

  Future<void> queueOperation({
    required String id,
    required String collection,
    required SyncOperationType operation,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final op = SyncOperation(
      id: id,
      collection: collection,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
    );

    await offlineQueue.enqueue(op);
    debugPrint('SYNC_MANAGER: Queued $operation $collection/$id');

    if (connectivity.currentStatus == NetworkStatus.online) {
      scheduler.processQueue();
    }
  }

  int get pendingCount => _isInitialized ? offlineQueue.pendingCount : 0;

  void dispose() {
    scheduler.dispose();
    connectivity.dispose();
    _isInitialized = false;
  }
}
