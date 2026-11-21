import 'package:uuid/uuid.dart';

import '../core/text_direction.dart';

enum BlockType { heading1, heading2, heading3, paragraph, quote, centered }

extension BlockTypeLabel on BlockType {
  String get label => switch (this) {
        BlockType.heading1 => 'Heading 1',
        BlockType.heading2 => 'Heading 2',
        BlockType.heading3 => 'Heading 3',
        BlockType.paragraph => 'Paragraph',
        BlockType.quote => 'Quote',
        BlockType.centered => 'Centered',
      };
}

/// Character and paragraph formatting for one block.
class TextStyleData {
  final String fontFamily;
  final double fontSize; // points
  final bool bold;
  final bool italic;
  final bool underline;
  final int color; // ARGB
  final double lineHeight; // multiplier
  final double letterSpacing; // points

  const TextStyleData({
    this.fontFamily = 'Roboto',
    this.fontSize = 16,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color = 0xFF000000,
    this.lineHeight = 1.5,
    this.letterSpacing = 0,
  });

  TextStyleData copyWith({
    String? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    int? color,
    double? lineHeight,
    double? letterSpacing,
  }) =>
      TextStyleData(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        color: color ?? this.color,
        lineHeight: lineHeight ?? this.lineHeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
      );

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'color': color,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
      };

  factory TextStyleData.fromJson(Map<String, dynamic> j) => TextStyleData(
        fontFamily: j['fontFamily'] as String? ?? 'Roboto',
        fontSize: (j['fontSize'] as num?)?.toDouble() ?? 16,
        bold: j['bold'] as bool? ?? false,
        italic: j['italic'] as bool? ?? false,
        underline: j['underline'] as bool? ?? false,
        color: (j['color'] as num?)?.toInt() ?? 0xFF000000,
        lineHeight: (j['lineHeight'] as num?)?.toDouble() ?? 1.5,
        letterSpacing: (j['letterSpacing'] as num?)?.toDouble() ?? 0,
      );
}

/// Sensible starting style for a language: Nastaliq for Urdu, Roboto otherwise.
TextStyleData defaultStyleFor(String languageCode) => isRtlLanguage(languageCode)
    ? const TextStyleData(
        fontFamily: 'Noto Nastaliq Urdu', fontSize: 20, lineHeight: 2.0)
    : const TextStyleData();

/// One paragraph-level unit of content.
class Block {
  final String id;
  BlockType type;
  String text;
  bool? rtl; // null = follow the book's language
  TextStyleData style;

  Block({
    String? id,
    this.type = BlockType.paragraph,
    this.text = '',
    this.rtl,
    TextStyleData? style,
  })  : id = id ?? const Uuid().v4(),
        style = style ?? const TextStyleData();

  bool resolvedRtl(String languageCode) => rtl ?? isRtlLanguage(languageCode);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'rtl': rtl,
        'style': style.toJson(),
      };

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        id: j['id'] as String?,
        type: BlockType.values.byName(j['type'] as String? ?? 'paragraph'),
        text: j['text'] as String? ?? '',
        rtl: j['rtl'] as bool?,
        style: TextStyleData.fromJson(
            (j['style'] as Map<String, dynamic>?) ?? const {}),
      );
}

class Chapter {
  final String id;
  String title;
  final List<Block> blocks;

  Chapter({String? id, required this.title, List<Block>? blocks})
      : id = id ?? const Uuid().v4(),
        blocks = blocks ?? <Block>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: j['id'] as String?,
        title: j['title'] as String? ?? '',
        blocks: (j['blocks'] as List<dynamic>? ?? [])
            .map((b) => Block.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}

class Book {
  final String id;
  String title;
  String author;
  String languageCode;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    required this.chapters,
  });

  factory Book.create({
    required String title,
    required String author,
    required String languageCode,
  }) {
    final now = DateTime.now();
    return Book(
      id: const Uuid().v4(),
      title: title,
      author: author,
      languageCode: languageCode,
      createdAt: now,
      updatedAt: now,
      chapters: [
        Chapter(
          title: 'Chapter 1',
          blocks: [Block(style: defaultStyleFor(languageCode))],
        ),
      ],
    );
  }

  bool get isRtl => isRtlLanguage(languageCode);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'languageCode': languageCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        author: j['author'] as String? ?? '',
        languageCode: j['languageCode'] as String? ?? 'ur',
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        chapters: (j['chapters'] as List<dynamic>? ?? [])
            .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
