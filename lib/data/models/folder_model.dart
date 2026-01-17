import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.title,
    this.parentId,
    required this.type,
    required this.createdAt,
  });

  factory Folder.create({
    required String title,
    String? parentId,
    FolderType type = FolderType.notebook,
  }) {
    return Folder(
      id: const Uuid().v4(),
      title: title,
      parentId: parentId,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}
