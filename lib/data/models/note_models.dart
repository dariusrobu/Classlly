import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    pressure: (json['p'] as num?)?.toDouble() ?? 1.0,
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

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
    'createdAt': createdAt,
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    points: (json['points'] as List)
        .map((e) => StrokePoint.fromJson(e))
        .toList(),
    color: json['color'] as int,
    width: (json['width'] as num).toDouble(),
    createdAt: json['createdAt'] as int,
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

  TextBlock({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'createdAt': createdAt,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    id: json['id'] as String,
    text: json['text'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    createdAt: json['createdAt'] as int,
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

        id: json['id'] as String,

        title: json['title'] as String,

        color: json['color'] as int,

        createdAt: DateTime.parse(json['created_at'] as String),

        updatedAt: DateTime.parse(json['updated_at'] as String),

      );



  factory Notebook.create({required String title, int? color}) {

    final now = DateTime.now();

    return Notebook(

      id: const Uuid().v4(),

      title: title,

      color: color ?? 0xFF7C3AED, // Default Purple

      createdAt: now,

      updatedAt: now,

    );

  }

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

  String? notebookId; // Reference to Notebook



  Note({

    required this.id,

    required this.title,

    required this.strokes,

    required this.textBlocks,

    this.audioPath,

    required this.createdAt,

    required this.updatedAt,

    this.notebookId,

  });



  Map<String, dynamic> toJson() => {

        'id': id,

        'title': title,

        'strokes': strokes.map((s) => s.toJson()).toList(),

        'textBlocks': textBlocks.map((t) => t.toJson()).toList(),

        'audioPath': audioPath,

        'created_at': createdAt.toIso8601String(),

        'updated_at': updatedAt.toIso8601String(),

        'notebook_id': notebookId,

      };



  factory Note.fromJson(Map<String, dynamic> json) => Note(

        id: json['id'] as String,

        title: json['title'] as String,

        strokes: (json['strokes'] as List?)?.map((e) => Stroke.fromJson(e)).toList() ?? [],

        textBlocks: (json['textBlocks'] as List?)?.map((e) => TextBlock.fromJson(e)).toList() ?? [],

        audioPath: json['audioPath'] as String?,

        createdAt: DateTime.parse(json['created_at'] as String),

        updatedAt: DateTime.parse(json['updated_at'] as String),

        notebookId: json['notebook_id'] as String?,

      );



  factory Note.create({String title = 'Untitled', String? notebookId}) {

    final now = DateTime.now();

    return Note(

      id: const Uuid().v4(),

      title: title,

      strokes: [],

      textBlocks: [],

      createdAt: now,

      updatedAt: now,

      notebookId: notebookId,

    );

  }

}
