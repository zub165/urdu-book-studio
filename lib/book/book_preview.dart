import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/text_direction.dart';
import '../models/book.dart';

Widget previewBlock(
  BuildContext context,
  Block block,
  String languageCode, {
  BookTemplate? template,
}) {
  final rtl = block.resolvedRtl(languageCode);
  final style = block.style;
  final heading = switch (block.type) {
    BlockType.heading1 => true,
    BlockType.heading2 => true,
    BlockType.heading3 => true,
    _ => false,
  };
  final size = switch (block.type) {
    BlockType.heading1 => style.fontSize + 6,
    BlockType.heading2 => style.fontSize + 4,
    BlockType.heading3 => style.fontSize + 2,
    _ => style.fontSize,
  };
  final defaultColor = template != null ? Color(template.text) : null;
  final color = style.color == 0xFF000000 && defaultColor != null
      ? defaultColor
      : resolvedTextColor(context, style.color);
  return Padding(
    padding: EdgeInsets.symmetric(vertical: heading ? 10 : 7),
    child: Text(
      block.text.isEmpty ? ' ' : block.text,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: block.type == BlockType.centered
          ? TextAlign.center
          : TextAlign.start,
      style: TextStyle(
        fontFamily: style.fontFamily.isNotEmpty
            ? style.fontFamily
            : (heading ? template?.headingFont : template?.bodyFont),
        fontSize: size,
        height: style.lineHeight,
        letterSpacing: style.letterSpacing,
        color: color,
        fontWeight: heading || style.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: block.type == BlockType.quote || style.italic
            ? FontStyle.italic
            : FontStyle.normal,
        decoration: style.underline ? TextDecoration.underline : null,
      ),
    ),
  );
}

class ChapterPreview extends StatelessWidget {
  final Chapter chapter;
  final String languageCode;
  final BookTemplate? template;

  const ChapterPreview({
    super.key,
    required this.chapter,
    required this.languageCode,
    this.template,
  });

  @override
  Widget build(BuildContext context) {
    final tpl = template ?? bookTemplateById('classic');
    return Directionality(
      textDirection:
          isRtlLanguage(languageCode) ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: Color(tpl.background),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: Color(tpl.surface),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          chapter.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(tpl.text),
                            fontFamily: tpl.headingFont,
                          ),
                        ),
                        Divider(height: 32, color: Color(tpl.accent).withValues(alpha: 0.35)),
                        for (final block in chapter.blocks)
                          previewBlock(context, block, languageCode, template: tpl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookPreview extends StatelessWidget {
  final Book book;

  const BookPreview({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final tpl = bookTemplateById(book.templateId);
    final rtl = book.isRtl;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: Color(tpl.background),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: Color(tpl.accent).withValues(alpha: 0.12),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          book.title.isEmpty ? 'Untitled book' : book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: tpl.headingFont,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(tpl.text),
                          ),
                        ),
                        if (book.author.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            book.author,
                            style: TextStyle(
                              color: Color(tpl.text).withValues(alpha: 0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final chapter in book.chapters) ...[
                  Card(
                    color: Color(tpl.surface),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            chapter.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(tpl.text),
                              fontFamily: tpl.headingFont,
                            ),
                          ),
                          Divider(height: 28, color: Color(tpl.accent).withValues(alpha: 0.35)),
                          for (final block in chapter.blocks)
                            previewBlock(context, block, book.languageCode, template: tpl),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
