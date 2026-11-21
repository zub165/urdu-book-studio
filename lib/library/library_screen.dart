import 'package:flutter/material.dart';

import '../book/book_screen.dart';
import '../core/constants.dart';
import '../core/text_direction.dart';
import '../models/book.dart';
import '../storage/book_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repo = BookRepository();
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Urdu Book Studio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? const Center(child: Text('No books yet. Tap "New book" to start.'))
              : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, i) {
                    final book = _books[i];
                    final rtl = book.isRtl;
                    return ListTile(
                      leading: Icon(rtl ? Icons.translate : Icons.menu_book),
                      title: Text(
                        book.title.isEmpty ? 'Untitled book' : book.title,
                        textDirection:
                            rtl ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      subtitle: Text(
                        '${languageName(book.languageCode)} · '
                        '${book.chapters.length} chapters',
                      ),
                      onTap: () => _open(book),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(book),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('New book'),
      ),
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
