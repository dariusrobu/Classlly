import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:classlly/core/utils/json_utils.dart';

part 'note_models.g.dart';

@HiveType(typeId: 0)
class StrokePoint extends HiveObject {
  @HiveField(0)
  final double x;
  @HiveField(1)
  final double y;
  @HiveField(2)
  final double pressure;

  StrokePoint({required this.x, required this.y, this.pressure = 1.0});

  Map<String, dynamic> toJson() => {
    'x': double.parse(x.toStringAsFixed(1)),
    'y': double.parse(y.toStringAsFixed(1)),
    'p': double.parse(pressure.toStringAsFixed(2)),
  };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
    x: JsonUtils.asDouble(json['x']),
    y: JsonUtils.asDouble(json['y']),
    pressure: JsonUtils.asDouble(json['p'], defaultValue: 1.0),
  );
}

@HiveType(typeId: 1)
class Stroke extends HiveObject {
  @HiveField(0)
  final List<StrokePoint> points;
  @HiveField(1)
  final int color;
  @HiveField(2)
  final double width;
  @HiveField(3)
  final int createdAt;
  @HiveField(4, defaultValue: 'pen')
  final String toolType;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.createdAt,
    this.toolType = 'pen',
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
    'createdAt': createdAt,
    'toolType': toolType,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    points: JsonUtils.asList(json['points'], (e) => StrokePoint.fromJson(e)),
    color: JsonUtils.asInt(json['color']),
    width: JsonUtils.asDouble(json['width']),
    createdAt: JsonUtils.asInt(json['createdAt']),
    toolType: JsonUtils.asString(json['toolType'], defaultValue: 'pen'),
  );
}

@HiveType(typeId: 2)
class TextBlock extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String text;
  @HiveField(2)
  final double x;
  @HiveField(3)
  final double y;
  @HiveField(4)
  final int createdAt;
  @HiveField(5, defaultValue: 0xFF000000)
  final int color;
  @HiveField(6, defaultValue: 16.0)
  final double fontSize;
  @HiveField(7, defaultValue: false)
  final bool isBold;
  @HiveField(8, defaultValue: false)
  final bool hasBackground;
  @HiveField(9, defaultValue: false)
  final bool isItalic;
  @HiveField(10, defaultValue: false)
  final bool isUnderline;

  TextBlock({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.createdAt,
    this.color = 0xFF000000,
    this.fontSize = 16.0,
    this.isBold = false,
    this.hasBackground = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'createdAt': createdAt,
    'color': color,
    'fontSize': fontSize,
    'isBold': isBold,
    'hasBackground': hasBackground,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    id: JsonUtils.asString(json['id']),
    text: JsonUtils.asString(json['text']),
    x: JsonUtils.asDouble(json['x']),
    y: JsonUtils.asDouble(json['y']),
    createdAt: JsonUtils.asInt(json['createdAt']),
    color: JsonUtils.asInt(json['color'], defaultValue: 0xFF000000),
    fontSize: JsonUtils.asDouble(json['fontSize'], defaultValue: 16.0),
    isBold: JsonUtils.asBool(json['isBold']),
    hasBackground: JsonUtils.asBool(json['hasBackground']),
    isItalic: JsonUtils.asBool(json['isItalic']),
    isUnderline: JsonUtils.asBool(json['isUnderline']),
  );
}

@HiveType(typeId: 4)
class Notebook extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  int color;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  DateTime updatedAt;

  Notebook({
    required this.id,
    required this.title,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
    id: JsonUtils.asString(json['id']),
    title: JsonUtils.asString(json['title']),
    color: JsonUtils.asInt(json['color']),
    createdAt: JsonUtils.asDateTime(json['created_at']),
    updatedAt: JsonUtils.asDateTime(json['updated_at']),
  );

  factory Notebook.create({required String title, int? color}) {
    final now = DateTime.now();
    return Notebook(
      id: const Uuid().v4(),
      title: title,
      color: color ?? 0xFF7C3AED,
      createdAt: now,
      updatedAt: now,
    );
  }
}

@HiveType(typeId: 5)
class ImageBlock extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String base64Data;
  @HiveField(2)
  double x;
  @HiveField(3)
  double y;
  @HiveField(4)
  double width;
  @HiveField(5)
  double height;
  @HiveField(6)
  final int createdAt;
  @HiveField(7)
  String? storagePath;

  ImageBlock({
    required this.id,
    required this.base64Data,
    required this.x,
    required this.y,
    this.width = 300,
    this.height = 300,
    required this.createdAt,
    this.storagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': storagePath != null ? null : base64Data, // Only send base64 if no storagePath
    'path': storagePath,
    'x': x,
    'y': y,
    'w': width,
    'h': height,
    'createdAt': createdAt,
  };

  factory ImageBlock.fromJson(Map<String, dynamic> json) => ImageBlock(
    id: JsonUtils.asString(json['id']),
    base64Data: JsonUtils.asString(json['data']),
    x: JsonUtils.asDouble(json['x']),
    y: JsonUtils.asDouble(json['y']),
    width: JsonUtils.asDouble(json['w'], defaultValue: 300.0),
    height: JsonUtils.asDouble(json['h'], defaultValue: 300.0),
    createdAt: JsonUtils.asInt(json['createdAt']),
    storagePath: JsonUtils.asString(json['path']),
  );
}

@HiveType(typeId: 3)
class Note extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  final List<Stroke> strokes;
  @HiveField(3)
  final List<TextBlock> textBlocks;
  @HiveField(4)
  String? audioPath;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  DateTime updatedAt;
  @HiveField(7)
  String? notebookId;
  @HiveField(8)
  String templateType;
  @HiveField(9, defaultValue: [])
  final List<ImageBlock> images;
  @HiveField(10)
  List<String>? tags;
  @HiveField(11, defaultValue: false)
  bool isDeleted;
  @HiveField(12, defaultValue: 'drawing')
  final String type;

  static const String typeDrawing = 'drawing';
  static const String typeText = 'text';

  Note({
    required this.id,
    required this.title,
    required this.strokes,
    required this.textBlocks,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
    this.notebookId,
    this.templateType = 'dot',
    required this.images,
    this.tags,
    this.isDeleted = false,
    this.type = 'drawing',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'textBlocks': textBlocks.map((t) => t.toJson()).toList(),
    'images': images.map((i) => i.toJson()).toList(),
    'audioPath': audioPath,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'notebook_id': notebookId,
    'template_type': templateType,
    'tags': tags,
    'is_deleted': isDeleted,
    'type': type,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    return Note(
      id: JsonUtils.asString(json['id']),
      title: JsonUtils.asString(json['title']),
      strokes: JsonUtils.asList(
        json['strokes'] ?? content['strokes'],
        (e) => Stroke.fromJson(e),
      ),
      textBlocks: JsonUtils.asList(
        json['textBlocks'] ?? content['textBlocks'],
        (e) => TextBlock.fromJson(e),
      ),
      images: JsonUtils.asList(
        json['images'] ?? content['images'],
        (e) => ImageBlock.fromJson(e),
      ),
      audioPath: (json['audioPath'] ?? content['audioPath']) as String?,
      createdAt: JsonUtils.asDateTime(json['created_at']),
      updatedAt: JsonUtils.asDateTime(json['updated_at']),
      notebookId: (json['notebook_id'] ?? content['notebook_id']) as String?,
      templateType: JsonUtils.asString(
        json['template_type'] ?? content['template_type'],
        defaultValue: 'dot',
      ),
      tags: JsonUtils.asList(
        json['tags'] ?? content['tags'],
        (e) => e as String,
      ),
      isDeleted: JsonUtils.asBool(json['is_deleted'] ?? content['is_deleted']),
      type: JsonUtils.asString(
        json['type'] ?? content['type'],
        defaultValue: 'drawing',
      ),
    );
  }

  factory Note.create({
    String title = 'Untitled',
    String? notebookId,
    String template = 'dot',
    String type = 'drawing',
  }) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      title: title,
      strokes: [],
      textBlocks: [],
      images: [],
      createdAt: now,
      updatedAt: now,
      notebookId: notebookId,
      templateType: template,
      tags: [],
      isDeleted: false,
      type: type,
    );
  }
}
