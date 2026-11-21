import 'package:flutter/material.dart';

import '../models/book.dart';
import 'font_toolbar.dart';

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

  Block? get _active {
    final i = _activeIndex;
    if (i == null || i >= widget.chapter.blocks.length) return null;
    return widget.chapter.blocks[i];
  }

  void _touch() {
    widget.onChanged();
    setState(() {});
  }

  void _applyStyle(TextStyleData next) {
    final block = _active;
    if (block == null) return;
    block.style = next;
    _touch();
  }

  void _addBlock(BlockType type) {
    widget.chapter.blocks.add(
      Block(type: type, style: defaultStyleFor(widget.book.languageCode)),
    );
    _activeIndex = widget.chapter.blocks.length - 1;
    _touch();
  }

  void _deleteBlock(int index) {
    widget.chapter.blocks.removeAt(index);
    _activeIndex = null;
    _touch();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.book.languageCode;
    final blocks = widget.chapter.blocks;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        actions: [
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
                      key: ValueKey(blocks[i].id),
                      block: blocks[i],
                      languageCode: lang,
                      selected: _activeIndex == i,
                      onFocus: () => setState(() => _activeIndex = i),
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
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _BlockTile({
    super.key,
    required this.block,
    required this.languageCode,
    required this.selected,
    required this.onFocus,
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
