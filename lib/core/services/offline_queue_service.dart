import 'package:hive/hive.dart';

enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id;
  final String collection;
  final SyncOperationType operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.collection,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection': collection,
    'operation': operation.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    collection: json['collection'] as String,
    operation: SyncOperationType.values.firstWhere(
      (e) => e.name == json['operation'],
      orElse: () => SyncOperationType.create,
    ),
    data: Map<String, dynamic>.from(json['data'] as Map),
    timestamp: DateTime.parse(json['timestamp'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

class OfflineQueueService {
  static const String boxName = 'offline_sync_queue';
  static const int maxRetries = 3;

  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Box<Map> get box {
    if (_box == null) {
      throw StateError(
        'OfflineQueueService not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  Future<void> enqueue(SyncOperation operation) async {
    await box.put(operation.id, operation.toJson());
  }

  Future<List<SyncOperation>> getPendingOperations() async {
    return box.values
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> remove(String operationId) async {
    await box.delete(operationId);
  }

  Future<void> incrementRetry(String operationId) async {
    final data = box.get(operationId);
    if (data != null) {
      final operation = SyncOperation.fromJson(Map<String, dynamic>.from(data));
      operation.retryCount++;
      await box.put(operationId, operation.toJson());
    }
  }

  Future<void> clear() async {
    await box.clear();
  }

  int get pendingCount => box.length;

  Future<bool> shouldRetry(String operationId) async {
    final data = box.get(operationId);
    if (data == null) return false;
    final operation = SyncOperation.fromJson(Map<String, dynamic>.from(data));
    return operation.retryCount < maxRetries;
  }
}
