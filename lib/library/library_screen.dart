import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../book/book_screen.dart';
import '../core/constants.dart';
import '../core/text_direction.dart';
import '../models/book.dart';
import '../storage/book_importer.dart';
import '../storage/book_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repo = BookRepository();
  final _search = TextEditingController();
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final books = await _repo.loadAll();
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<void> _persist() => _repo.saveAll(_books);

  Future<void> _createBook() async {
    final book = await showDialog<Book>(
      context: context,
      builder: (_) => const _NewBookDialog(),
    );
    if (book == null) return;
    setState(() => _books.insert(0, book));
    await _persist();
    if (!mounted) return;
    await _open(book);
  }

  Future<void> _importBook() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    if (!mounted) return;
    final language = await showDialog<String>(
      context: context,
      builder: (_) => const _LanguagePickerDialog(),
    );
    if (language == null) return;
    try {
      final imported =
          await BookImporter(languageCode: language).import(file.bytes!, file.name);
      setState(() => _books.insert(0, imported));
      await _persist();
      if (!mounted) return;
      await _open(imported);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _open(Book book) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookScreen(book: book, onChanged: _persist),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _delete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('"${book.title}" will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _books.remove(book));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _books.where((book) {
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          languageName(book.languageCode).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urdu Book Studio'),
        actions: [
          IconButton(
            tooltip: 'Import book file',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _importBook,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search books, authors or languages',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 72,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _books.isEmpty
                                    ? 'No books yet. Tap "New book" or import a file.'
                                    : 'No matching books.',
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final book = visible[i];
                            final color = languageColor(book.languageCode);
                            final rtl = book.isRtl;
                            final initial = book.title.isEmpty
                                ? '?'
                                : String.fromCharCode(book.title.runes.first);
                            return Card(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withValues(alpha: 0.22),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    child: Text(initial.toUpperCase()),
                                  ),
                                  title: Text(
                                    book.title.isEmpty ? 'Untitled book' : book.title,
                                    textDirection:
                                        rtl ? TextDirection.rtl : TextDirection.ltr,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Chip(
                                          label: Text(
                                            languageName(book.languageCode),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Text('${book.chapters.length} chapters'),
                                        Text(
                                          book.updatedAt
                                              .toIso8601String()
                                              .substring(0, 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _open(book),
                                  trailing: IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(book),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('New book'),
      ),
    );
  }
}

class _LanguagePickerDialog extends StatefulWidget {
  const _LanguagePickerDialog();

  @override
  State<_LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<_LanguagePickerDialog> {
  String _language = 'ur';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Imported book language'),
      content: DropdownButtonFormField<String>(
        initialValue: _language,
        items: [
          for (final l in kLanguages)
            DropdownMenuItem(value: l.code, child: Text(l.name)),
        ],
        onChanged: (v) {
          if (v != null) setState(() => _language = v);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _language),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _NewBookDialog extends StatefulWidget {
  const _NewBookDialog();

  @override
  State<_NewBookDialog> createState() => _NewBookDialogState();
}

class _NewBookDialogState extends State<_NewBookDialog> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  String _language = 'ur';

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    Navigator.pop(
      context,
      Book.create(
        title: title.isEmpty ? 'Untitled book' : title,
        author: _author.text.trim(),
        languageCode: _language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = isRtlLanguage(_language);
    return AlertDialog(
      title: const Text('New book'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _author,
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: [
                for (final l in kLanguages)
                  DropdownMenuItem(value: l.code, child: Text(l.name)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _language = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
