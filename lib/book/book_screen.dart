import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../editor/chapter_editor.dart';
import '../export/exporter.dart';
import '../models/book.dart';
import '../storage/book_importer.dart';
import 'book_preview.dart';

class BookScreen extends StatefulWidget {
  final Book book;
  final Future<void> Function() onChanged;

  const BookScreen({super.key, required this.book, required this.onChanged});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  bool _preview = false;

  Book get book => widget.book;

  void _save() {
    book.updatedAt = DateTime.now();
    widget.onChanged();
  }

  void _changed() {
    _save();
    setState(() {});
  }

  Future<void> _addChapter() async {
    final title = await _askText(
      context,
      'New chapter',
      'Chapter ${book.chapters.length + 1}',
    );
    if (title == null) return;
    book.chapters.add(Chapter(
      title: title,
      blocks: [Block(style: defaultStyleFor(book.languageCode))],
    ));
    _changed();
  }

  Future<void> _renameChapter(Chapter chapter) async {
    final title = await _askText(context, 'Rename chapter', chapter.title);
    if (title == null) return;
    chapter.title = title;
    _changed();
  }

  void _deleteChapter(Chapter chapter) {
    book.chapters.remove(chapter);
    if (book.chapters.isEmpty) {
      book.chapters.add(Chapter(
        title: 'Chapter 1',
        blocks: [Block(style: defaultStyleFor(book.languageCode))],
      ));
    }
    _changed();
  }

  void _openChapter(Chapter chapter) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ChapterEditor(
            book: book,
            chapter: chapter,
            chapters: book.chapters,
            onChanged: _save,
          ),
        ))
        .then((_) => mounted ? setState(() {}) : null);
  }

  Future<void> _importIntoBook() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    try {
      final imported = await BookImporter(languageCode: book.languageCode)
          .import(file.bytes!, file.name);
      book.chapters.addAll(imported.chapters);
      _changed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${imported.chapters.length} chapters')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _export(BookExporter exporter) async {
    final bytes = await exporter.export(book);
    final base = book.title.trim().isEmpty ? 'book' : book.title.trim();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export ${exporter.label}',
      fileName: '$base.${exporter.extension}',
      bytes: bytes,
    );
    if (!mounted || path == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${exporter.label}')),
    );
  }

  void _showKpfGuide() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kindle (KPF) export'),
        content: const SizedBox(
          width: 420,
          child: Text(
            'KPF is Amazon\'s proprietary Kindle format, so this app exports EPUB '
            'instead. To create KPF:\n\n'
            '1. Export EPUB from this app.\n'
            '2. Open the file in Kindle Create, choose Reflowable, and continue.\n'
            '3. Use File > Export and select KPF (Kindle and print).\n\n'
            'You can also upload the EPUB or DOCX directly to Kindle Direct Publishing.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = book.isRtl;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title.isEmpty ? 'Untitled book' : book.title),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Book template',
            icon: const Icon(Icons.palette_outlined),
            onSelected: (id) {
              book.templateId = id;
              _changed();
            },
            itemBuilder: (_) => [
              for (final t in kBookTemplates)
                PopupMenuItem(
                  value: t.id,
                  child: Row(
                    children: [
                      if (t.id == book.templateId) const Icon(Icons.check, size: 18),
                      if (t.id == book.templateId) const SizedBox(width: 8),
                      Text(t.name),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: _preview ? 'Back to chapters' : 'Preview book',
            icon: Icon(_preview ? Icons.edit_note : Icons.visibility),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          IconButton(
            tooltip: 'Import file into this book',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importIntoBook,
          ),
          IconButton(
            tooltip: 'Kindle (KPF) guide',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: _showKpfGuide,
          ),
          PopupMenuButton<BookExporter>(
            tooltip: 'Export',
            icon: const Icon(Icons.file_download_outlined),
            onSelected: _export,
            itemBuilder: (_) => [
              for (final e in kExporters)
                PopupMenuItem(value: e, child: Text(e.label)),
            ],
          ),
        ],
      ),
      body: _preview
          ? BookPreview(book: book)
          : Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: book.title,
                    decoration: const InputDecoration(labelText: 'Book title'),
                    onChanged: (v) {
                      book.title = v;
                      _save();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: book.author,
                    decoration: const InputDecoration(labelText: 'Author'),
                    onChanged: (v) {
                      book.author = v;
                      _save();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: book.chapters.length,
                onReorderItem: (oldIndex, newIndex) {
                  final chapter = book.chapters.removeAt(oldIndex);
                  book.chapters.insert(newIndex, chapter);
                  _changed();
                },
                itemBuilder: (context, i) {
                  final chapter = book.chapters[i];
                  return ListTile(
                    key: ValueKey(chapter.id),
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(chapter.title),
                    subtitle: Text('${chapter.blocks.length} paragraphs'),
                    onTap: () => _openChapter(chapter),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _renameChapter(chapter);
                        if (v == 'delete') _deleteChapter(chapter);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChapter,
        icon: const Icon(Icons.add),
        label: const Text('Chapter'),
      ),
    );
  }
}

Future<String?> _askText(
    BuildContext context, String title, String initial) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Title'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}
