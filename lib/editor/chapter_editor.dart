import 'package:flutter/material.dart';

import '../book/book_preview.dart';
import '../core/constants.dart';
import '../models/book.dart';
import '../services/ai_service.dart';
import 'ai_dialogs.dart';
import 'font_toolbar.dart';

class _ReplaceRequest {
  final String find;
  final String replace;
  final bool replaceAll;

  const _ReplaceRequest(this.find, this.replace, this.replaceAll);
}

/// Edits the blocks of one chapter. Each block has its own direction, so
/// Urdu paragraphs and English notes can sit side by side.
class ChapterEditor extends StatefulWidget {
  final Book book;
  final Chapter chapter;
  final List<Chapter> chapters;
  final VoidCallback onChanged;

  const ChapterEditor({
    super.key,
    required this.book,
    required this.chapter,
    required this.chapters,
    required this.onChanged,
  });

  @override
  State<ChapterEditor> createState() => _ChapterEditorState();
}

class _ChapterEditorState extends State<ChapterEditor>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Chapter _chapter;
  int? _activeIndex;
  int _revision = 0;
  AiSettings _aiSettings = const AiSettings();
  final List<List<Map<String, dynamic>>> _undo = [];
  final List<List<Map<String, dynamic>>> _redo = [];

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _tabs = TabController(length: 5, vsync: this);
    AiSettingsStore().load().then((settings) {
      if (mounted) setState(() => _aiSettings = settings);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Block? get _active {
    final i = _activeIndex;
    if (i == null || i >= _chapter.blocks.length) return null;
    return _chapter.blocks[i];
  }

  String get _languageCode => widget.book.languageCode;

  int get _wordCount => _chapter.blocks
      .expand((b) => b.text.trim().split(RegExp(r'\s+')))
      .where((w) => w.isNotEmpty)
      .length;

  int get _characterCount =>
      _chapter.blocks.fold<int>(0, (total, block) => total + block.text.length);

  List<Map<String, dynamic>> _snapshot() =>
      _chapter.blocks.map((b) => b.toJson()).toList();

  void _record() {
    _undo.add(_snapshot());
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(List<Map<String, dynamic>> snapshot) {
    _chapter.blocks
      ..clear()
      ..addAll(snapshot.map(Block.fromJson));
    _revision++;
  }

  void _undoChange() {
    if (_undo.isEmpty) return;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
    _touch();
  }

  void _redoChange() {
    if (_redo.isEmpty) return;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
    _touch();
  }

  void _touch() {
    widget.onChanged();
    setState(() {});
  }

  void _applyStyle(TextStyleData next) {
    final block = _active;
    if (block == null) return;
    _record();
    block.style = next;
    _touch();
  }

  void _addBlock(BlockType type) {
    _record();
    _chapter.blocks.add(
      Block(type: type, style: defaultStyleFor(_languageCode)),
    );
    _activeIndex = _chapter.blocks.length - 1;
    _touch();
    _tabs.animateTo(0);
  }

  void _deleteBlock(int index) {
    _record();
    _chapter.blocks.removeAt(index);
    _activeIndex = null;
    _touch();
  }

  void _insertBlocks(List<Block> blocks) {
    _record();
    _chapter.blocks.addAll(blocks);
    _revision++;
    _touch();
    _tabs.animateTo(0);
  }

  void _selectChapter(Chapter chapter) {
    if (chapter.id != _chapter.id) {
      setState(() {
        _chapter = chapter;
        _activeIndex = null;
        _undo.clear();
        _redo.clear();
        _revision++;
      });
    }
    Navigator.of(context).pop();
  }

  void _jumpToBlock(int index) {
    setState(() => _activeIndex = index);
    _tabs.animateTo(0);
  }

  void _flipDirection() {
    final block = _active;
    if (block == null) return;
    _record();
    block.rtl = !block.resolvedRtl(_languageCode);
    _touch();
  }

  Future<void> _openAiSettings() async {
    final updated = await showDialog<AiSettings>(
      context: context,
      builder: (_) => AiSettingsDialog(settings: _aiSettings),
    );
    if (updated == null) return;
    await AiSettingsStore().save(updated);
    if (!mounted) return;
    setState(() => _aiSettings = updated);
  }

  Future<void> _aiTranslate() async {
    final result = await showDialog<AiInsertResult>(
      context: context,
      builder: (_) => TranslateDialog(
        settings: _aiSettings,
        bookLanguage: _languageCode,
      ),
    );
    if (result != null && mounted) _insertBlocks(result.blocks);
  }

  Future<void> _aiOutline() async {
    final result = await showDialog<AiInsertResult>(
      context: context,
      builder: (_) => OutlineDialog(
        settings: _aiSettings,
        languageCode: _languageCode,
      ),
    );
    if (result != null && mounted) _insertBlocks(result.blocks);
  }

  Future<void> _findAndReplace() async {
    final request = await showDialog<_ReplaceRequest>(
      context: context,
      builder: (_) => const _FindReplaceDialog(),
    );
    if (request == null || request.find.isEmpty) return;
    final found =
        _chapter.blocks.any((b) => b.text.contains(request.find));
    if (!found) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches found')),
      );
      return;
    }
    _record();
    for (final block in _chapter.blocks) {
      if (!block.text.contains(request.find)) continue;
      block.text = request.replaceAll
          ? block.text.replaceAll(request.find, request.replace)
          : block.text.replaceFirst(request.find, request.replace);
    }
    _revision++;
    _touch();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chapter.title),
            Text(
              '$_wordCount words · $_characterCount characters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _undo.isNotEmpty ? _undoChange : null,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: _redo.isNotEmpty ? _redoChange : null,
          ),
          IconButton(
            tooltip: 'Find and replace',
            icon: const Icon(Icons.search),
            onPressed: _findAndReplace,
          ),
          PopupMenuButton<String>(
            tooltip: 'AI tools',
            icon: const Icon(Icons.auto_awesome),
            onSelected: (value) {
              if (value == 'translate') _aiTranslate();
              if (value == 'outline') _aiOutline();
              if (value == 'settings') _openAiSettings();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'translate', child: Text('Translate text')),
              PopupMenuItem(
                value: 'outline',
                child: Text('Generate heading outline'),
              ),
              PopupMenuItem(value: 'settings', child: Text('AI settings')),
            ],
          ),
          PopupMenuButton<BlockType>(
            tooltip: 'Add block',
            icon: const Icon(Icons.add),
            onSelected: _addBlock,
            itemBuilder: (_) => [
              for (final t in BlockType.values)
                PopupMenuItem(value: t, child: Text(t.label)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Write'),
            Tab(icon: Icon(Icons.format_paint), text: 'Format'),
            Tab(icon: Icon(Icons.visibility), text: 'Preview'),
            Tab(icon: Icon(Icons.list_alt), text: 'Outline'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI'),
          ],
        ),
      ),
      drawer: _buildDrawer(scheme),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final editor = _buildEditorTabs();
          if (constraints.maxWidth < 1050) return editor;
          final pane = SizedBox(width: 380, child: _buildPreviewPane(scheme));
          final divider = Container(
            width: 1,
            color: scheme.outlineVariant,
          );
          return Row(
            children: widget.book.isRtl
                ? [pane, divider, Expanded(child: editor)]
                : [Expanded(child: editor), divider, pane],
          );
        },
      ),
    );
  }

  Widget _buildEditorTabs() => TabBarView(
        controller: _tabs,
        children: [
          _buildWriteTab(),
          _buildFormatTab(),
          ChapterPreview(chapter: _chapter, languageCode: _languageCode),
          _buildOutlineTab(),
          _buildAiTab(),
        ],
      );

  Widget _buildWriteTab() {
    final scheme = Theme.of(context).colorScheme;
    final blocks = _chapter.blocks;
    return Column(
      children: [
        Material(
          color: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FontToolbar(style: _active?.style, onChanged: _applyStyle),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: blocks.isEmpty
              ? const Center(child: Text('Tap + to add a paragraph.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: blocks.length,
                  itemBuilder: (context, i) => _BlockTile(
                    key: ValueKey('${blocks[i].id}_$_revision'),
                    block: blocks[i],
                    languageCode: _languageCode,
                    selected: _activeIndex == i,
                    onFocus: () => setState(() => _activeIndex = i),
                    onBeforeChange: _record,
                    onChanged: _touch,
                    onDelete: () => _deleteBlock(i),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFormatTab() {
    final block = _active;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected block', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (block == null)
                  const Text(
                    'Tap a paragraph in the Write tab first, then adjust its font and direction here.',
                  )
                else ...[
                  DropdownButtonFormField<BlockType>(
                    initialValue: block.type,
                    decoration: const InputDecoration(labelText: 'Block type'),
                    items: [
                      for (final type in BlockType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (type) {
                      if (type == null) return;
                      _record();
                      block.type = type;
                      _touch();
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Right to left paragraph'),
                    value: block.resolvedRtl(_languageCode),
                    onChanged: (_) => _flipDirection(),
                  ),
                  const Divider(height: 24),
                  FontToolbar(style: block.style, onChanged: _applyStyle),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineTab() {
    final headings = <MapEntry<int, Block>>[];
    for (var i = 0; i < _chapter.blocks.length; i++) {
      final block = _chapter.blocks[i];
      if (block.type == BlockType.heading1 ||
          block.type == BlockType.heading2 ||
          block.type == BlockType.heading3) {
        headings.add(MapEntry(i, block));
      }
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heading outline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${headings.length} headings in this chapter',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (headings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No headings yet. Add a heading block to build an outline.'),
            ),
          ),
        for (final entry in headings)
          Card(
            child: ListTile(
              leading: Icon(
                entry.value.type == BlockType.heading1
                    ? Icons.title
                    : entry.value.type == BlockType.heading2
                        ? Icons.format_size
                        : Icons.text_fields,
              ),
              title: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: (entry.value.type.index == 0
                          ? 0
                          : entry.value.type.index == 1
                              ? 16
                              : 32)
                      .toDouble(),
                ),
                child: Text(
                  entry.value.text.isEmpty ? '(empty heading)' : entry.value.text,
                  textDirection: entry.value.resolvedRtl(_languageCode)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ),
              onTap: () => _jumpToBlock(entry.key),
            ),
          ),
      ],
    );
  }

  Widget _buildAiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: _aiSettings.isConfigured
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(
              _aiSettings.isConfigured
                  ? '${_aiSettings.provider.label} ready'
                  : 'AI is not configured',
            ),
            subtitle: Text(
              _aiSettings.isConfigured
                  ? 'Model: ${_aiSettings.model}'
                  : 'Add a Gemini or OpenAI key to enable translation and outlines.',
            ),
            trailing: TextButton(
              onPressed: _openAiSettings,
              child: const Text('Settings'),
            ),
          ),
        ),
        _AiActionCard(
          icon: Icons.translate,
          title: 'Translate text',
          subtitle: 'Translate a template into Urdu or another language.',
          onTap: _aiTranslate,
        ),
        _AiActionCard(
          icon: Icons.account_tree_outlined,
          title: 'Heading outline',
          subtitle: 'Generate chapter headings, then insert them as blocks.',
          onTap: _aiOutline,
        ),
        _AiActionCard(
          icon: Icons.key_outlined,
          title: 'API key',
          subtitle: 'Change provider, model or locally stored API key.',
          onTap: _openAiSettings,
        ),
      ],
    );
  }

  Widget _buildPreviewPane(ColorScheme scheme) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            child: ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Live preview'),
              subtitle: const Text('Updates as you type'),
              trailing: IconButton(
                tooltip: 'Open preview tab',
                icon: const Icon(Icons.open_in_full),
                onPressed: () => _tabs.animateTo(2),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(child: ChapterPreview(chapter: _chapter, languageCode: _languageCode)),
        ],
      );

  Widget _buildDrawer(ColorScheme scheme) {
    final color = languageColor(_languageCode);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.85), color],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.title.isEmpty ? 'Untitled book' : widget.book.title,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  _chapter.title,
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Chip(
                  label: Text(languageName(_languageCode)),
                  backgroundColor: Colors.white24,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Chapters',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final chapter in widget.chapters)
            ListTile(
              selected: chapter.id == _chapter.id,
              leading: const Icon(Icons.bookmark_border),
              title: Text(chapter.title),
              onTap: () => _selectChapter(chapter),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Insert block',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final type in BlockType.values)
            ListTile(
              leading: Icon(_iconForType(type)),
              title: Text(type.label),
              onTap: () {
                _addBlock(type);
                Navigator.of(context).pop();
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Find and replace'),
            onTap: () {
              Navigator.of(context).pop();
              _findAndReplace();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Flip paragraph direction'),
            onTap: () {
              _flipDirection();
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Undo'),
            onTap: _undo.isNotEmpty
                ? () {
                    _undoChange();
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.redo),
            title: const Text('Redo'),
            onTap: _redo.isNotEmpty
                ? () {
                    _redoChange();
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI settings'),
            onTap: () {
              Navigator.of(context).pop();
              _openAiSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Back to book'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForType(BlockType type) => switch (type) {
        BlockType.heading1 => Icons.title,
        BlockType.heading2 => Icons.format_size,
        BlockType.heading3 => Icons.text_fields,
        BlockType.quote => Icons.format_quote,
        BlockType.centered => Icons.format_align_center,
        BlockType.paragraph => Icons.notes,
      };
}

class _AiActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final Block block;
  final String languageCode;
  final bool selected;
  final VoidCallback onFocus;
  final VoidCallback onBeforeChange;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _BlockTile({
    super.key,
    required this.block,
    required this.languageCode,
    required this.selected,
    required this.onFocus,
    required this.onBeforeChange,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = block.resolvedRtl(languageCode);
    final s = block.style;
    final scheme = Theme.of(context).colorScheme;

    final textStyle = TextStyle(
      fontFamily: s.fontFamily,
      fontSize: s.fontSize,
      height: s.lineHeight,
      letterSpacing: s.letterSpacing,
      fontWeight: s.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
      decoration: s.underline ? TextDecoration.underline : TextDecoration.none,
      color: resolvedTextColor(context, s.color),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DropdownButton<BlockType>(
                value: block.type,
                isDense: true,
                items: [
                  for (final t in BlockType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (t) {
                  if (t == null) return;
                  onBeforeChange();
                  block.type = t;
                  onChanged();
                },
              ),
              const Spacer(),
              IconButton(
                tooltip: rtl
                    ? 'Switch to left-to-right'
                    : 'Switch to right-to-left',
                icon: Icon(rtl
                    ? Icons.format_textdirection_r_to_l
                    : Icons.format_textdirection_l_to_r),
                onPressed: () {
                  onBeforeChange();
                  block.rtl = !rtl;
                  onChanged();
                },
              ),
              IconButton(
                tooltip: 'Delete block',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          TextFormField(
            initialValue: block.text,
            onTap: onFocus,
            onChanged: (v) {
              onBeforeChange();
              block.text = v;
              onChanged();
            },
            maxLines: null,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: TextAlign.start,
            style: textStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Write here...',
            ),
          ),
        ],
      ),
    );
  }
}

class _FindReplaceDialog extends StatefulWidget {
  const _FindReplaceDialog();

  @override
  State<_FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<_FindReplaceDialog> {
  final _find = TextEditingController();
  final _replace = TextEditingController();
  bool _replaceAll = false;

  @override
  void dispose() {
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Find and replace'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _find,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Find'),
            ),
            TextField(
              controller: _replace,
              decoration: const InputDecoration(labelText: 'Replace with'),
            ),
            CheckboxListTile(
              value: _replaceAll,
              onChanged: (v) => setState(() => _replaceAll = v ?? false),
              title: const Text('Replace all'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ReplaceRequest(
              _find.text,
              _replace.text,
              _replaceAll,
            ),
          ),
          child: const Text('Replace'),
        ),
      ],
    );
  }
}
