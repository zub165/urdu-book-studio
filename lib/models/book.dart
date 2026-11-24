import 'package:uuid/uuid.dart';

import '../core/constants.dart';
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

/// Sensible starting style for a language, using its bundled script font.
TextStyleData defaultStyleFor(String languageCode) {
  final primary = languageCode.split(RegExp('[-_]')).first.toLowerCase();
  final font = fontForLanguage(primary);
  if (font != null) {
    return TextStyleData(
      fontFamily: font,
      fontSize: primary == 'ur' ? 20 : 18,
      lineHeight: primary == 'ur' ? 2.0 : 1.8,
    );
  }
  return isRtlLanguage(languageCode)
      ? const TextStyleData(
          fontFamily: 'Noto Naskh Arabic', fontSize: 18, lineHeight: 1.8)
      : const TextStyleData();
}

/// One paragraph-level unit of content.
class Block {
  final String id;
  BlockType type;
  String text;
  bool? rtl; // null = follow the book's language
  double paragraphSpacing; // points before/after spacing in preview/export
  TextStyleData style;

  Block({
    String? id,
    this.type = BlockType.paragraph,
    this.text = '',
    this.rtl,
    this.paragraphSpacing = 8,
    TextStyleData? style,
  })  : id = id ?? const Uuid().v4(),
        style = style ?? const TextStyleData();

  bool resolvedRtl(String languageCode) => rtl ?? isRtlLanguage(languageCode);

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type.name, 'text': text, 'rtl': rtl, 'paragraphSpacing': paragraphSpacing, 'style': style.toJson(),
      };

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        id: j['id'] as String?,
        type: BlockType.values.byName(j['type'] as String? ?? 'paragraph'),
        text: j['text'] as String? ?? '',
        rtl: j['rtl'] as bool?,
        paragraphSpacing: (j['paragraphSpacing'] as num?)?.toDouble() ?? 8,
        style: TextStyleData.fromJson((j['style'] as Map<String, dynamic>?) ?? const {}),
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

class BookComment {
  final String id;
  String text;
  String chapterTitle;
  bool resolved;
  final DateTime createdAt;

  BookComment({String? id, required this.text, this.chapterTitle = '', this.resolved = false, DateTime? createdAt})
      : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id, 'text': text, 'chapterTitle': chapterTitle, 'resolved': resolved, 'createdAt': createdAt.toIso8601String(),
      };
  factory BookComment.fromJson(Map<String, dynamic> j) => BookComment(
        id: j['id'] as String?, text: j['text'] as String? ?? '', chapterTitle: j['chapterTitle'] as String? ?? '',
        resolved: j['resolved'] as bool? ?? false, createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class BookSnapshot {
  final String id;
  final String label;
  final DateTime createdAt;
  final Map<String, dynamic> bookData;

  BookSnapshot({String? id, required this.label, DateTime? createdAt, required this.bookData})
      : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'createdAt': createdAt.toIso8601String(), 'bookData': bookData};
  factory BookSnapshot.fromJson(Map<String, dynamic> j) => BookSnapshot(
        id: j['id'] as String?, label: j['label'] as String? ?? 'Snapshot',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        bookData: Map<String, dynamic>.from(j['bookData'] as Map? ?? const {}),
      );
}

class Book {
  final String id;
  String title;
  String subtitle;
  String author;
  String description;
  String isbn;
  String languageCode;
  String templateId;
  String? coverImageBase64;
  String pageSize; // a4, a5, letter, 6x9
  double marginMm;
  bool showPageNumbers;
  bool generateToc;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<Chapter> frontMatter;
  final List<Chapter> chapters;
  final List<Chapter> backMatter;
  final List<BookComment> comments;
  final List<BookSnapshot> snapshots;

  Book({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.author,
    this.description = '',
    this.isbn = '',
    required this.languageCode,
    this.templateId = 'classic',
    this.coverImageBase64,
    this.pageSize = 'a5',
    this.marginMm = 20,
    this.showPageNumbers = true,
    this.generateToc = true,
    required this.createdAt,
    required this.updatedAt,
    List<Chapter>? frontMatter,
    required this.chapters,
    List<Chapter>? backMatter,
    List<BookComment>? comments,
    List<BookSnapshot>? snapshots,
  })  : frontMatter = frontMatter ?? <Chapter>[],
        backMatter = backMatter ?? <Chapter>[],
        comments = comments ?? <BookComment>[],
        snapshots = snapshots ?? <BookSnapshot>[];

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
      templateId: isRtlLanguage(languageCode) ? 'urdu_nastaliq' : 'classic',
      createdAt: now,
      updatedAt: now,
      frontMatter: [
        Chapter(title: 'Title Page', blocks: [
          Block(type: BlockType.centered, text: title, style: defaultStyleFor(languageCode)),
        ]),
      ],
      chapters: [
        Chapter(
          title: 'Chapter 1',
          blocks: [Block(style: defaultStyleFor(languageCode))],
        ),
      ],
      backMatter: [
        Chapter(title: 'Acknowledgments', blocks: [
          Block(style: defaultStyleFor(languageCode)),
        ]),
      ],
    );
  }

  bool get isRtl => isRtlLanguage(languageCode);

  List<Chapter> get allChapters => [...frontMatter, ...chapters, ...backMatter];

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'subtitle': subtitle, 'author': author, 'description': description, 'isbn': isbn,
        'languageCode': languageCode, 'templateId': templateId, 'coverImageBase64': coverImageBase64,
        'pageSize': pageSize, 'marginMm': marginMm, 'showPageNumbers': showPageNumbers, 'generateToc': generateToc,
        'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
        'frontMatter': frontMatter.map((c) => c.toJson()).toList(),
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'backMatter': backMatter.map((c) => c.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        author: j['author'] as String? ?? '',
        description: j['description'] as String? ?? '',
        isbn: j['isbn'] as String? ?? '',
        languageCode: j['languageCode'] as String? ?? 'ur',
        templateId: j['templateId'] as String? ?? 'classic',
        coverImageBase64: j['coverImageBase64'] as String?,
        pageSize: j['pageSize'] as String? ?? 'a5',
        marginMm: (j['marginMm'] as num?)?.toDouble() ?? 20,
        showPageNumbers: j['showPageNumbers'] as bool? ?? true,
        generateToc: j['generateToc'] as bool? ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        frontMatter: (j['frontMatter'] as List<dynamic>? ?? []).map((c) => Chapter.fromJson(c as Map<String, dynamic>)).toList(),
        chapters: (j['chapters'] as List<dynamic>? ?? []).map((c) => Chapter.fromJson(c as Map<String, dynamic>)).toList(),
        backMatter: (j['backMatter'] as List<dynamic>? ?? []).map((c) => Chapter.fromJson(c as Map<String, dynamic>)).toList(),
        comments: (j['comments'] as List<dynamic>? ?? []).map((c) => BookComment.fromJson(c as Map<String, dynamic>)).toList(),
        snapshots: (j['snapshots'] as List<dynamic>? ?? []).map((s) => BookSnapshot.fromJson(s as Map<String, dynamic>)).toList(),
      );
}
