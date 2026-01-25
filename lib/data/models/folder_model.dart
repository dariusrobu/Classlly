import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'folder_model.g.dart';

@HiveType(typeId: 11)
enum FolderType {
  @HiveField(0)
  notebook,
  @HiveField(1)
  resource,
}

@HiveType(typeId: 12)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? parentId;
  @HiveField(3)
  FolderType type;
  @HiveField(4)
  DateTime? createdAt;
  @HiveField(5)
  DateTime? updatedAt;
  @HiveField(6, defaultValue: false)
  bool isDeleted;

  Folder({
    required this.id,
    required this.title,
    this.parentId,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  }) {
    createdAt ??= DateTime.now();
    updatedAt ??= DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'parent_id': parentId,
    'type': type == FolderType.resource ? 'resource' : 'notebook',
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'is_deleted': isDeleted,
  };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title'], defaultValue: 'Untitled Folder'),
    parentId: JsonUtils.asString(json['parent_id']),
    type: JsonUtils.asString(json['type']) == 'resource'
        ? FolderType.resource
        : FolderType.notebook,
    createdAt: JsonUtils.asDateTime(json['created_at']),
    updatedAt: JsonUtils.asDateTime(json['updated_at']),
    isDeleted: JsonUtils.asBool(json['is_deleted']),
  );

  factory Folder.create({
    required String title,
    String? parentId,
    FolderType type = FolderType.notebook,
  }) {
    final now = DateTime.now();
    return Folder(
      id: const Uuid().v4(),
      title: title,
      parentId: parentId,
      type: type,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }
}
