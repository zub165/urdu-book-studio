import 'package:flutter/material.dart';

import '../models/book.dart';
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
  final VoidCallback onChanged;

  const ChapterEditor({
    super.key,
    required this.book,
    required this.chapter,
    required this.onChanged,
  });

  @override
  State<ChapterEditor> createState() => _ChapterEditorState();
}

class _ChapterEditorState extends State<ChapterEditor> {
  int? _activeIndex;
  int _revision = 0;
  final List<List<Map<String, dynamic>>> _undo = [];
  final List<List<Map<String, dynamic>>> _redo = [];

  Block? get _active {
    final i = _activeIndex;
    if (i == null || i >= widget.chapter.blocks.length) return null;
    return widget.chapter.blocks[i];
  }

  int get _wordCount => widget.chapter.blocks
      .expand((b) => b.text.trim().split(RegExp(r'\s+')))
      .where((w) => w.isNotEmpty)
      .length;

  int get _characterCount => widget.chapter.blocks.fold<int>(
      0, (total, block) => total + block.text.length);

  List<Map<String, dynamic>> _snapshot() =>
      widget.chapter.blocks.map((b) => b.toJson()).toList();

  void _record() {
    _undo.add(_snapshot());
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(List<Map<String, dynamic>> snapshot) {
    widget.chapter.blocks
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
    widget.chapter.blocks.add(
      Block(type: type, style: defaultStyleFor(widget.book.languageCode)),
    );
    _activeIndex = widget.chapter.blocks.length - 1;
    _touch();
  }

  void _deleteBlock(int index) {
    _record();
    widget.chapter.blocks.removeAt(index);
    _activeIndex = null;
    _touch();
  }

  Future<void> _findAndReplace() async {
    final request = await showDialog<_ReplaceRequest>(
      context: context,
      builder: (_) => const _FindReplaceDialog(),
    );
    if (request == null || request.find.isEmpty) return;
    final found = widget.chapter.blocks
        .any((b) => b.text.contains(request.find));
    if (!found) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches found')),
      );
      return;
    }
    _record();
    for (final block in widget.chapter.blocks) {
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
    final lang = widget.book.languageCode;
    final blocks = widget.chapter.blocks;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chapter.title),
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FontToolbar(style: _active?.style, onChanged: _applyStyle),
          ),
          const Divider(height: 1),
          Expanded(
            child: blocks.isEmpty
                ? const Center(child: Text('Tap + to add a paragraph.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blocks.length,
                    itemBuilder: (context, i) => _BlockTile(
                      key: ValueKey('${blocks[i].id}_$_revision'),
                      block: blocks[i],
                      languageCode: lang,
                      selected: _activeIndex == i,
                      onFocus: () => setState(() => _activeIndex = i),
                      onBeforeChange: _record,
                      onChanged: _touch,
                      onDelete: () => _deleteBlock(i),
                    ),
                  ),
          ),
        ],
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
      color: Color(s.color),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? scheme.primary : Colors.black12,
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
                tooltip: rtl ? 'Switch to left-to-right' : 'Switch to right-to-left',
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
