import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';

class SyncScheduler {
  final OfflineQueueService _queueService;
  final ConnectivityService _connectivityService;
  final SupabaseClient _client = Supabase.instance.client;

  Timer? _periodicSyncTimer;
  StreamSubscription? _connectivitySubscription;

  static const Duration syncInterval = Duration(minutes: 5);

  SyncScheduler({
    required OfflineQueueService queueService,
    required ConnectivityService connectivityService,
  }) : _queueService = queueService,
       _connectivityService = connectivityService;

  void start() {
    _periodicSyncTimer = Timer.periodic(syncInterval, (_) => _syncNow());

    _connectivitySubscription = _connectivityService.statusStream.listen((
      status,
    ) {
      if (status == NetworkStatus.online) {
        debugPrint('SYNC_SCHEDULER: Online - processing queue');
        processQueue();
      }
    });

    if (_connectivityService.currentStatus == NetworkStatus.online) {
      processQueue();
    }
  }

  Future<void> _syncNow() async {
    if (_connectivityService.currentStatus == NetworkStatus.online) {
      await processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_connectivityService.currentStatus != NetworkStatus.online) {
      debugPrint('SYNC_SCHEDULER: Offline - skipping sync');
      return;
    }

    final operations = await _queueService.getPendingOperations();
    if (operations.isEmpty) {
      debugPrint('SYNC_SCHEDULER: No pending operations');
      return;
    }

    debugPrint('SYNC_SCHEDULER: Processing ${operations.length} operations');

    for (final op in operations) {
      try {
        await _processOperation(op);
        await _queueService.remove(op.id);
        debugPrint(
          'SYNC_SCHEDULER: Processed ${op.operation.name} ${op.collection}/${op.id}',
        );
      } catch (e) {
        debugPrint('SYNC_SCHEDULER: Error processing ${op.id}: $e');

        if (await _queueService.shouldRetry(op.id)) {
          await _queueService.incrementRetry(op.id);
        } else {
          debugPrint(
            'SYNC_SCHEDULER: Max retries exceeded for ${op.id}, removing',
          );
          await _queueService.remove(op.id);
        }
      }
    }
  }

  Future<void> _processOperation(SyncOperation op) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('No user logged in');
    }

    final data = {
      'id': op.id,
      'user_id': uid,
      'collection': op.collection,
      'data': op.data,
      'updated_at': DateTime.now().toIso8601String(),
    };

    switch (op.operation) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        await _client.from('sync_store').upsert(data);
        break;
      case SyncOperationType.delete:
        await _client
            .from('sync_store')
            .delete()
            .eq('id', op.id)
            .eq('collection', op.collection);
        break;
    }
  }

  void stop() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  void dispose() {
    stop();
  }
}
