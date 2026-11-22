import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../book/book_screen.dart';
import '../core/app_strings.dart';
import '../core/constants.dart';
import '../core/text_direction.dart';
import '../models/book.dart';
import '../services/app_settings.dart';
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
  String _sort = 'recent';
  String _languageFilter = 'all';
  Book? _lastDeleted;
  int _lastDeletedIndex = -1;

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
    final s = AppStrings.of(context);
    final idx = _books.indexOf(book);
    setState(() {
      _books.remove(book);
      _lastDeleted = book;
      _lastDeletedIndex = idx;
    });
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${s.moveToTrash}: "${book.title}"'),
      action: SnackBarAction(label: s.undo, onPressed: () async {
        final b = _lastDeleted;
        if (b == null) return;
        setState(() => _books.insert(_lastDeletedIndex.clamp(0, _books.length), b));
        _lastDeleted = null;
        await _persist();
      }),
    ));
  }

  Future<void> _duplicate(Book book) async {
    final json = book.toJson();
    json['id'] = const Uuid().v4();
    json['title'] = '${book.title} (Copy)';
    final now = DateTime.now().toIso8601String();
    json['createdAt'] = now;
    json['updatedAt'] = now;
    final copy = Book.fromJson(json);
    setState(() => _books.insert(0, copy));
    await _persist();
  }

  Future<void> _editDetails(Book book) async {
    final s = AppStrings.of(context);
    final title = TextEditingController(text: book.title);
    final author = TextEditingController(text: book.author);
    var lang = book.languageCode;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text(s.editDetails),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: InputDecoration(labelText: s.title)),
        const SizedBox(height: 8),
        TextField(controller: author, decoration: InputDecoration(labelText: s.author)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(initialValue: lang, decoration: InputDecoration(labelText: s.language),
          items: [for (final l in kLanguages) DropdownMenuItem(value: l.code, child: Text(l.name))],
          onChanged: (v) { if (v != null) setD(() => lang = v); }),
      ])),
      actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: Text(s.cancel)), FilledButton(onPressed: ()=>Navigator.pop(ctx,true), child: Text(s.ok))],
    )));
    if (ok != true) return;
    setState(() { book.title = title.text.trim(); book.author = author.text.trim(); book.languageCode = lang; book.updatedAt = DateTime.now(); });
    await _persist();
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _AppSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final query = _search.text.trim().toLowerCase();
    final visible = _books.where((book) {
      if (_languageFilter != 'all' && book.languageCode != _languageFilter) return false;
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          languageName(book.languageCode).toLowerCase().contains(query);
    }).toList();
    visible.sort((a,b) {
      switch (_sort) {
        case 'title': return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'author': return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case 'language': return a.languageCode.compareTo(b.languageCode);
        default: return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          FilledButton.icon(onPressed: _createBook, icon: const Icon(Icons.add), label: Text(s.newBook)),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: _importBook, icon: const Icon(Icons.file_upload_outlined), label: Text(s.importFile)),
          IconButton(tooltip: s.settings, icon: const Icon(Icons.settings_outlined), onPressed: _openSettings),
          const SizedBox(width: 8),
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
              child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 360, child: TextField(controller: _search, onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: s.searchHint, prefixIcon: const Icon(Icons.search), filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
                DropdownButton<String>(value: _sort, onChanged: (v)=>setState(()=>_sort=v ?? 'recent'), items: [
                  DropdownMenuItem(value: 'recent', child: Text(s.recentlyEdited)),
                  DropdownMenuItem(value: 'title', child: Text(s.sortTitle)),
                  DropdownMenuItem(value: 'author', child: Text(s.sortAuthor)),
                  DropdownMenuItem(value: 'language', child: Text(s.sortLanguage)),
                ]),
                DropdownButton<String>(value: _languageFilter, onChanged: (v)=>setState(()=>_languageFilter=v ?? 'all'), items: [
                  DropdownMenuItem(value: 'all', child: Text(s.allLanguages)),
                  for (final l in kLanguages) DropdownMenuItem(value: l.code, child: Text(l.name)),
                ]),
              ]),
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
                              Text(_books.isEmpty ? s.noBooks : s.noMatches),
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
                                    book.title.isEmpty ? s.untitledBook : book.title,
                                    textDirection:
                                        rtl ? TextDirection.rtl : TextDirection.ltr,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                      Chip(label: Text(languageName(book.languageCode), style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                                      Text('${book.chapters.length} ${s.chapters}'),
                                      Text('${s.lastEdited} ${MaterialLocalizations.of(context).formatMediumDate(book.updatedAt)}'),
                                    ]),
                                  ),
                                  onTap: () => _open(book),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'open') _open(book);
                                      if (v == 'edit') _editDetails(book);
                                      if (v == 'dup') _duplicate(book);
                                      if (v == 'del') _delete(book);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(value: 'open', child: Text(s.open)),
                                      PopupMenuItem(value: 'edit', child: Text(s.editDetails)),
                                      PopupMenuItem(value: 'dup', child: Text(s.duplicate)),
                                      PopupMenuItem(value: 'del', child: Text(s.moveToTrash)),
                                    ],
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
      floatingActionButton: MediaQuery.sizeOf(context).width < 700
          ? FloatingActionButton(onPressed: _createBook, tooltip: s.newBook, child: const Icon(Icons.add))
          : null,
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

class _AppSettingsDialog extends StatelessWidget {
  const _AppSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;
    return AlertDialog(
      title: Text(s.settings),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.appearance, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<AppThemeMode>(
                initialValue: settings.themeMode,
                decoration: InputDecoration(labelText: s.themeMode),
                items: [
                  DropdownMenuItem(value: AppThemeMode.system, child: Text(s.system)),
                  DropdownMenuItem(value: AppThemeMode.light, child: Text(s.light)),
                  DropdownMenuItem(value: AppThemeMode.dark, child: Text(s.dark)),
                  DropdownMenuItem(value: AppThemeMode.sepia, child: Text(s.sepia)),
                ],
                onChanged: (v) {
                  if (v != null) controller.update(settings.copyWith(themeMode: v));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppThemeColor>(
                initialValue: settings.themeColor,
                decoration: InputDecoration(labelText: s.themeColor),
                items: [
                  for (final c in AppThemeColor.values)
                    DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 8, backgroundColor: Color(c.color)),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) controller.update(settings.copyWith(themeColor: v));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: settings.localeCode,
                decoration: InputDecoration(labelText: s.appLanguage),
                items: [
                  for (final l in kAppLanguages)
                    DropdownMenuItem(
                      value: l.code,
                      child: Text('${l.name} — ${l.nativeName}'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) controller.update(settings.copyWith(localeCode: v));
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.ok)),
      ],
    );
  }
}
