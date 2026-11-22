import 'dart:convert';
import 'dart:typed_data';

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

class _BookScreenState extends State<BookScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _author = TextEditingController();
  final _description = TextEditingController();
  final _isbn = TextEditingController();

  Book get book => widget.book;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _syncControllers();
  }

  void _syncControllers() {
    _title.text = book.title;
    _subtitle.text = book.subtitle;
    _author.text = book.author;
    _description.text = book.description;
    _isbn.text = book.isbn;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _subtitle.dispose();
    _author.dispose();
    _description.dispose();
    _isbn.dispose();
    super.dispose();
  }

  void _save() {
    book.updatedAt = DateTime.now();
    widget.onChanged();
  }

  void _changed() {
    _save();
    setState(() {});
  }

  Future<String?> _askText(String title, String initial, {String label = 'Title'}) async {
    final c = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _addChapter([List<Chapter>? target]) async {
    target ??= book.chapters;
    final title = await _askText('New chapter/section', 'Section ${target.length + 1}');
    if (title == null) return;
    target.add(Chapter(title: title, blocks: [Block(style: defaultStyleFor(book.languageCode))]));
    _changed();
  }

  Future<void> _renameChapter(Chapter chapter) async {
    final title = await _askText('Rename', chapter.title);
    if (title == null) return;
    chapter.title = title;
    _changed();
  }

  void _deleteChapter(List<Chapter> target, Chapter chapter) {
    if (target.length <= 1 && identical(target, book.chapters)) return;
    target.remove(chapter);
    if (book.chapters.isEmpty) {
      book.chapters.add(Chapter(title: 'Chapter 1', blocks: [Block(style: defaultStyleFor(book.languageCode))]));
    }
    _changed();
  }

  void _openChapter(Chapter chapter) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChapterEditor(book: book, chapter: chapter, chapters: book.allChapters, onChanged: _save),
    )).then((_) => mounted ? setState(() {}) : null);
  }

  Future<void> _importIntoBook() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    try {
      final imported = await BookImporter(languageCode: book.languageCode).import(file.bytes!, file.name);
      book.chapters.addAll(imported.chapters);
      _changed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${imported.chapters.length} chapters')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported ${exporter.label}')));
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.single.bytes == null) return;
    book.coverImageBase64 = base64Encode(result.files.single.bytes!);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title.isEmpty ? 'Untitled book' : book.title),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.library_books_outlined), text: 'My Books'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Outline'),
            Tab(icon: Icon(Icons.edit_note), text: 'Write'),
            Tab(icon: Icon(Icons.rate_review_outlined), text: 'Review'),
            Tab(icon: Icon(Icons.auto_awesome_mosaic_outlined), text: 'Layout'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Cover & Details'),
            Tab(icon: Icon(Icons.visibility_outlined), text: 'Preview'),
            Tab(icon: Icon(Icons.publish_outlined), text: 'Export & Publish'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: book.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildMyBooks(),
            _buildOutline(),
            _buildWrite(),
            _buildReview(),
            _buildLayout(),
            _buildCoverDetails(),
            BookPreview(book: book),
            _buildExport(),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, Widget child, {List<Widget>? actions}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ...?actions,
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  Widget _buildMyBooks() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Project', Column(children: [
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Book title'), onChanged: (v) { book.title = v; _save(); }),
        const SizedBox(height: 8),
        TextField(controller: _author, decoration: const InputDecoration(labelText: 'Author'), onChanged: (v) { book.author = v; _save(); }),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: book.languageCode,
          decoration: const InputDecoration(labelText: 'Book language / writing language'),
          items: [for (final l in kLanguages) DropdownMenuItem(value: l.code, child: Text(l.name))],
          onChanged: (v) { if (v == null) return; book.languageCode = v; _changed(); },
        ),
        const SizedBox(height: 8),
        Text(book.isRtl ? 'Default direction: Right to left (RTL)' : 'Default direction: Left to right (LTR)', style: Theme.of(context).textTheme.bodySmall),
      ])),
      _sectionCard('Actions', Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: _importIntoBook, icon: const Icon(Icons.file_upload_outlined), label: const Text('Import manuscript')),
        OutlinedButton.icon(onPressed: () => _tabs.animateTo(2), icon: const Icon(Icons.edit), label: const Text('Open draft')),
        OutlinedButton.icon(onPressed: () => _tabs.animateTo(6), icon: const Icon(Icons.visibility), label: const Text('Preview')),
      ])),
      _sectionCard('Status', Wrap(spacing: 16, runSpacing: 8, children: [
        Chip(label: Text('${book.allChapters.length} sections')),
        Chip(label: Text('${book.chapters.length} chapters')),
        Chip(label: Text('Updated ${book.updatedAt.toIso8601String().substring(0, 10)}')),
      ])),
    ]);
  }

  Future<void> _addSection(List<Chapter> target, String title) async {
    final t = await _askText('Add page', title);
    if (t == null) return;
    target.add(Chapter(title: t, blocks: [Block(style: defaultStyleFor(book.languageCode))]));
    _changed();
  }

  Widget _addMenu(String tooltip, List<String> items, void Function(String) onPick) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      icon: const Icon(Icons.add_circle_outline),
      onSelected: onPick,
      itemBuilder: (_) => [for (final item in items) PopupMenuItem(value: item, child: Text(item))],
    );
  }

  Widget _chapterList(String title, List<Chapter> target, {required List<String> addItems}) {
    return _sectionCard(title, ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: target.length,
      onReorderItem: (oldIndex, newIndex) {
        final c = target.removeAt(oldIndex);
        target.insert(newIndex, c);
        _changed();
      },
      itemBuilder: (context, i) {
        final c = target[i];
        return ListTile(
          key: ValueKey(c.id),
          leading: const Icon(Icons.drag_handle),
          title: Text(c.title),
          subtitle: Text('${c.blocks.length} blocks'),
          onTap: () => _openChapter(c),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(tooltip: 'Rename', icon: const Icon(Icons.edit_outlined), onPressed: () => _renameChapter(c)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rename') _renameChapter(c);
                if (v == 'delete') _deleteChapter(target, c);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
        );
      },
    ), actions: [_addMenu('Add $title', addItems, (v) => _addSection(target, v == 'Custom page' ? '' : v))]);
  }

  Widget _buildOutline() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _chapterList('Front matter', book.frontMatter, addItems: const ['Title Page','Copyright','Dedication','Epigraph','Table of Contents','Preface','Introduction','Prologue','Foreword','Custom page']),
      _chapterList('Body', book.chapters, addItems: const ['Part Page','Chapter Page','Custom page']),
      _chapterList('Back matter', book.backMatter, addItems: const ['Books by This Author','About the Author','Books in This Series','Praise for Author','Epilogue','Afterword','Acknowledgments','Custom page']),
      _sectionCard('Outline tips', const Text('Use + to add pages to Front Matter, Body, or Back Matter. Drag to reorder. Tap a page to edit. Use Rename beside each page.')),
    ]);
  }

  Widget _buildWrite() {
    final chapter = book.chapters.isNotEmpty ? book.chapters.first : (book.allChapters.isNotEmpty ? book.allChapters.first : null);
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Write', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Use the chapter editor for full drafting. Chapter list is in Outline/My Books; editor keeps undo/redo, word count, find/replace, and autosave.'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (chapter != null)
            FilledButton.icon(onPressed: () => _openChapter(chapter), icon: const Icon(Icons.edit), label: Text('Open "${chapter.title}"')),
          OutlinedButton.icon(onPressed: _addChapter, icon: const Icon(Icons.add), label: const Text('Add chapter')),
        ]),
      ])),
      _sectionCard('Quick chapter access', Column(children: [
        for (final c in book.allChapters.take(20))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(c.title),
            subtitle: Text('${c.blocks.length} blocks'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openChapter(c),
          ),
      ])),
    ]);
  }

  void _addComment() async {
    final c = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add comment'),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Comment')),
      actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx, c.text.trim()), child: const Text('Add'))],
    ));
    c.dispose();
    if (result == null || result.isEmpty) return;
    book.comments.add(BookComment(text: result));
    _changed();
  }

  void _createSnapshot() {
    book.snapshots.insert(0, BookSnapshot(label: 'Snapshot ${book.snapshots.length + 1} · ${DateTime.now().toIso8601String().substring(0,16).replaceFirst("T"," ")}', bookData: book.toJson()));
    if (book.snapshots.length > 20) book.snapshots.removeLast();
    _changed();
  }

  void _restoreSnapshot(BookSnapshot snap) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Restore snapshot?'),
      content: Text('Restore "${snap.label}"? Current unsaved state will be replaced.'),
      actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Restore'))],
    ));
    if (ok != true) return;
    final restored = Book.fromJson(snap.bookData);
    book.title = restored.title; book.subtitle = restored.subtitle; book.author = restored.author; book.description = restored.description; book.isbn = restored.isbn;
    book.languageCode = restored.languageCode; book.templateId = restored.templateId; book.coverImageBase64 = restored.coverImageBase64; book.pageSize = restored.pageSize;
    book.marginMm = restored.marginMm; book.showPageNumbers = restored.showPageNumbers; book.generateToc = restored.generateToc;
    book.frontMatter..clear()..addAll(restored.frontMatter);
    book.chapters..clear()..addAll(restored.chapters);
    book.backMatter..clear()..addAll(restored.backMatter);
    book.comments..clear()..addAll(restored.comments);
    _syncControllers();
    _changed();
  }

  Widget _buildReview() {
    final words = book.allChapters.expand((c) => c.blocks).expand((b) => b.text.trim().split(RegExp(r'\s+'))).where((w) => w.isNotEmpty).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Review status', Wrap(spacing: 12, runSpacing: 8, children: [
        Chip(label: Text('$words words')),
        Chip(label: Text('${book.allChapters.length} sections')),
        const Chip(label: Text('Autosave: on')),
        Chip(label: Text('${book.comments.where((c)=>!c.resolved).length} open comments')),
      ])),
      _sectionCard('Checks', const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(leading: Icon(Icons.spellcheck), title: Text('Spelling'), subtitle: Text('Use system/editor spellcheck while writing; language follows book/passage settings.')),
        ListTile(leading: Icon(Icons.comment_outlined), title: Text('Comments'), subtitle: Text('Add review comments below and mark them resolved.')),
        ListTile(leading: Icon(Icons.history), title: Text('Snapshots'), subtitle: Text('Create/restore local snapshots for draft recovery.')),
      ])),
      _sectionCard('Comments', Column(children: [
        Align(alignment: AlignmentDirectional.centerStart, child: FilledButton.icon(onPressed: _addComment, icon: const Icon(Icons.add_comment_outlined), label: const Text('Add comment'))),
        const SizedBox(height: 8),
        if (book.comments.isEmpty) const ListTile(contentPadding: EdgeInsets.zero, title: Text('No comments yet.')),
        for (final c in book.comments)
          CheckboxListTile(
            value: c.resolved,
            onChanged: (v) { c.resolved = v ?? false; _changed(); },
            title: Text(c.text, style: TextStyle(decoration: c.resolved ? TextDecoration.lineThrough : null)),
            subtitle: Text(c.createdAt.toIso8601String().substring(0,16).replaceFirst('T',' ')),
            secondary: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { book.comments.remove(c); _changed(); }),
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ])),
      _sectionCard('Version snapshots', Column(children: [
        Align(alignment: AlignmentDirectional.centerStart, child: FilledButton.tonalIcon(onPressed: _createSnapshot, icon: const Icon(Icons.save_as_outlined), label: const Text('Save snapshot'))),
        const SizedBox(height: 8),
        if (book.snapshots.isEmpty) const ListTile(contentPadding: EdgeInsets.zero, title: Text('No snapshots yet.')),
        for (final s in book.snapshots)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(s.label),
            subtitle: Text(s.createdAt.toIso8601String().substring(0,16).replaceFirst('T',' ')),
            trailing: Wrap(spacing: 4, children: [
              TextButton(onPressed: () => _restoreSnapshot(s), child: const Text('Restore')),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { book.snapshots.remove(s); _changed(); }),
            ]),
          ),
      ])),
    ]);
  }

  Widget _buildLayout() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Typography & template', Column(children: [
        DropdownButtonFormField<String>(
          initialValue: book.templateId,
          decoration: const InputDecoration(labelText: 'Template'),
          items: [for (final t in kBookTemplates) DropdownMenuItem(value: t.id, child: Text(t.name))],
          onChanged: (v) { if (v == null) return; book.templateId = v; _changed(); },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: book.pageSize,
          decoration: const InputDecoration(labelText: 'Print page size'),
          items: const [
            DropdownMenuItem(value: 'a4', child: Text('A4')),
            DropdownMenuItem(value: 'a5', child: Text('A5')),
            DropdownMenuItem(value: 'letter', child: Text('Letter')),
            DropdownMenuItem(value: '6x9', child: Text('6x9 in')),
          ],
          onChanged: (v) { if (v == null) return; book.pageSize = v; _changed(); },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Margins: ${book.marginMm.round()} mm')),
          Expanded(child: Slider(value: book.marginMm.clamp(10, 40), min: 10, max: 40, divisions: 30, onChanged: (v) { book.marginMm = v; _changed(); })),
        ]),
        SwitchListTile(title: const Text('Show page numbers'), value: book.showPageNumbers, onChanged: (v) { book.showPageNumbers = v; _changed(); }),
        SwitchListTile(title: const Text('Generate table of contents'), value: book.generateToc, onChanged: (v) { book.generateToc = v; _changed(); }),
      ])),
      _sectionCard('Paragraph direction', const Text('Each block can be LTR/RTL in the editor. Book language sets default direction; mixed Urdu/English passages are supported per block.')),
    ]);
  }

  Widget _buildCoverDetails() {
    Uint8List? coverBytes;
    if (book.coverImageBase64 != null && book.coverImageBase64!.isNotEmpty) {
      try { coverBytes = base64Decode(book.coverImageBase64!); } catch (_) {}
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Cover', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (coverBytes != null)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Image.memory(coverBytes, height: 220, fit: BoxFit.contain)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: _pickCover, icon: const Icon(Icons.upload), label: const Text('Upload cover')),
          if (book.coverImageBase64 != null)
            OutlinedButton.icon(onPressed: () { book.coverImageBase64 = null; _changed(); }, icon: const Icon(Icons.delete_outline), label: const Text('Remove')),
        ]),
        const SizedBox(height: 8),
        Text('Ebook front cover supported. Print full cover (front/spine/back) is not generated yet; export front cover and assemble print cover in your print service.', style: Theme.of(context).textTheme.bodySmall),
      ])),
      _sectionCard('Book details', Column(children: [
        TextField(controller: _subtitle, decoration: const InputDecoration(labelText: 'Subtitle'), onChanged: (v) { book.subtitle = v; _save(); }),
        const SizedBox(height: 8),
        TextField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description'), onChanged: (v) { book.description = v; _save(); }),
        const SizedBox(height: 8),
        TextField(controller: _isbn, decoration: const InputDecoration(labelText: 'ISBN (optional)'), onChanged: (v) { book.isbn = v; _save(); }),
      ])),
    ]);
  }

  Widget _buildExport() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionCard('Export files', Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in kExporters)
          FilledButton.tonalIcon(onPressed: () => _export(e), icon: const Icon(Icons.download), label: Text(e.label)),
      ])),
      _sectionCard('Publish checklist', Column(children: [
        ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('Metadata complete'), subtitle: Text(book.title.isNotEmpty && book.author.isNotEmpty ? 'Title/author set' : 'Add title and author in Cover & Details/My Books')),
        ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Cover image'), subtitle: Text(book.coverImageBase64 != null ? 'Front cover attached' : 'Add cover in Cover & Details')),
        ListTile(leading: const Icon(Icons.menu_book_outlined), title: const Text('Table of contents'), subtitle: Text(book.generateToc ? 'TOC enabled in Layout' : 'TOC disabled in Layout')),
      ])),
      _sectionCard('Publish targets', const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(leading: Icon(Icons.storefront_outlined), title: Text('Amazon KDP'), subtitle: Text('Export EPUB (ebook) or DOCX/PDF (print workflow). KPF is proprietary; convert EPUB/DOCX in Kindle Create if needed.')),
        ListTile(leading: Icon(Icons.public_outlined), title: Text('Other platforms'), subtitle: Text('Export EPUB/DOCX/PDF and upload to Apple Books, Google Play Books, Draft2Digital, etc.')),
        SizedBox(height: 8),
        Text('Direct platform submission requires provider APIs/credentials and is not enabled in this local build.'),
      ])),
    ]);
  }
}
