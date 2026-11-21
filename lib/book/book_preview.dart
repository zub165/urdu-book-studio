import 'package:flutter/material.dart';

import '../core/text_direction.dart';
import '../models/book.dart';

Widget previewBlock(Block block, String languageCode) {
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
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      block.text.isEmpty ? ' ' : block.text,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: block.type == BlockType.centered
          ? TextAlign.center
          : TextAlign.start,
      style: TextStyle(
        fontFamily: style.fontFamily,
        fontSize: size,
        height: style.lineHeight,
        letterSpacing: style.letterSpacing,
        color: Color(style.color),
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

  const ChapterPreview({
    super.key,
    required this.chapter,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtlLanguage(languageCode) ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            chapter.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          for (final block in chapter.blocks) previewBlock(block, languageCode),
        ],
      ),
    );
  }
}

class BookPreview extends StatelessWidget {
  final Book book;

  const BookPreview({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = book.isRtl;
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Text(
                    book.title.isEmpty ? 'Untitled book' : book.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: defaultStyleFor(book.languageCode).fontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (book.author.isNotEmpty)
                    Text(
                      book.author,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final chapter in book.chapters) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      chapter.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    for (final block in chapter.blocks)
                      previewBlock(block, book.languageCode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
