import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../book/book_preview.dart';
import '../core/constants.dart';
import '../core/text_direction.dart';
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
  final Set<int> _selected = <int>{};
  bool _selectMode = false;
  bool _continuousView = true;
  String _applyScope = 'selected'; // selected, chapter, book
  int _revision = 0;
  AiSettings _aiSettings = const AiSettings();
  final List<List<Map<String, dynamic>>> _undo = [];
  final List<List<Map<String, dynamic>>> _redo = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _showUrduKeyboard = false;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    if (_chapter.blocks.isNotEmpty) _activeIndex = 0;
    _tabs = TabController(length: 5, vsync: this);
    AiSettingsStore().load().then((settings) {
      if (mounted) setState(() => _aiSettings = settings);
    });
  }

  TextEditingController _controllerFor(Block block) {
    final c = _controllers.putIfAbsent(block.id, () => TextEditingController(text: block.text));
    if (c.text != block.text) c.value = c.value.copyWith(text: block.text, selection: TextSelection.collapsed(offset: block.text.length), composing: TextRange.empty);
    return c;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    _tabs.dispose();
    super.dispose();
  }

  Block? get _active {
    final i = _activeIndex;
    if (i == null || i >= _chapter.blocks.length) return null;
    return _chapter.blocks[i];
  }

  String get _languageCode => widget.book.languageCode;
  String _saveStatus = 'Saved';

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
    setState(() => _saveStatus = 'Saving…');
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _saveStatus = 'Saved');
    });
  }


  List<Block> _scopeBlocks() {
    if (_applyScope == 'book') return [for (final c in widget.book.allChapters) ...c.blocks];
    if (_applyScope == 'chapter') return _chapter.blocks;
    final idx = _targetIndexes.toList();
    if (idx.isEmpty) return _active == null ? <Block>[] : [_active!];
    return [for (final i in idx) _chapter.blocks[i]];
  }
  Iterable<int> get _targetIndexes {
    if (_selected.isNotEmpty) return _selected;
    final i = _activeIndex;
    if (i == null || i >= _chapter.blocks.length) return const <int>[];
    return [i];
  }

  void _applyStyle(TextStyleData next) {
    final targets = _scopeBlocks();
    if (targets.isEmpty) return;
    _record();
    for (final block in targets) {
      block.style = next.copyWith();
    }
    _touch();
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
      _selectMode = _selected.isNotEmpty || _selectMode;
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(List<int>.generate(_chapter.blocks.length, (i) => i));
      _selectMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  void _applyStyleToAll(TextStyleData next) {
    if (_chapter.blocks.isEmpty) return;
    _record();
    for (final block in _chapter.blocks) {
      block.style = next.copyWith();
    }
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
    final removed = _chapter.blocks.removeAt(index);
    _controllers.remove(removed.id)?.dispose();
    _selected.removeWhere((i) => i == index);
    _selected.clear(); // keep simple after structural change
    _activeIndex = _chapter.blocks.isEmpty ? null : (index > 0 ? index - 1 : 0);
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
        _activeIndex = chapter.blocks.isNotEmpty ? 0 : null;
        _selected.clear();
        _selectMode = false;
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
    final targets = _scopeBlocks();
    if (targets.isEmpty) return;
    _record();
    for (final b in targets) { b.rtl = !(b.rtl ?? isRtlLanguage(_languageCode)); }
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
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final c = TextEditingController(text: _chapter.title);
            final next = await showDialog<String>(context: context, builder: (ctx)=>AlertDialog(title: const Text('Rename chapter'), content: TextField(controller: c, autofocus: true), actions:[TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx,c.text.trim()), child: const Text('Save'))]));
            if (next != null && next.isNotEmpty) { setState(()=>_chapter.title = next); widget.onChanged(); }
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_chapter.title),
            Text('$_wordCount words · $_characterCount characters · $_saveStatus', style: Theme.of(context).textTheme.bodySmall),
          ]),
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
          if (!compact) ...[
            IconButton(tooltip: 'Save now', icon: const Icon(Icons.save_outlined), onPressed: () { widget.onChanged(); setState(()=>_saveStatus='Saved'); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'))); }),
            IconButton(tooltip: 'Urdu keyboard', icon: Icon(_showUrduKeyboard ? Icons.keyboard_hide : Icons.keyboard), onPressed: () => setState(()=>_showUrduKeyboard=!_showUrduKeyboard)),
            PopupMenuButton<BlockType>(
              tooltip: 'Set block type / heading',
              icon: const Icon(Icons.title),
              onSelected: (t) { _record(); for (final b in _scopeBlocks().isEmpty ? [_active].whereType<Block>() : _scopeBlocks()) { b.type = t; } _touch(); },
              itemBuilder: (_) => [for (final t in BlockType.values) PopupMenuItem(value: t, child: Text(t.label))],
            ),
            IconButton(
              tooltip: _continuousView ? 'Block edit view' : 'Continuous writing view',
              icon: Icon(_continuousView ? Icons.view_agenda_outlined : Icons.article_outlined),
              onPressed: () => setState(() { _continuousView = !_continuousView; _selectMode = false; _selected.clear(); }),
            ),
            IconButton(tooltip: 'Select all blocks', icon: const Icon(Icons.select_all), onPressed: _chapter.blocks.isEmpty ? null : _selectAll),
            if (!_continuousView)
              IconButton(
                tooltip: _selectMode ? 'Exit select mode' : 'Select blocks',
                icon: Icon(_selectMode ? Icons.checklist_rtl : Icons.checklist),
                onPressed: () => setState(() { _selectMode = !_selectMode; if (!_selectMode) _selected.clear(); }),
              ),
            IconButton(
              tooltip: 'Find and replace',
              icon: const Icon(Icons.search),
              onPressed: _findAndReplace,
            ),
          ],
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
          PopupMenuButton<String>(
            tooltip: 'Chapter actions',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'save') { widget.onChanged(); setState(()=>_saveStatus='Saved'); return; }
              if (v == 'keyboard') { setState(()=>_showUrduKeyboard=!_showUrduKeyboard); return; }
              if (v == 'view') { setState(() { _continuousView = !_continuousView; _selectMode = false; _selected.clear(); }); return; }
              if (v == 'selectmode') { setState(() { _selectMode = !_selectMode; if (!_selectMode) _selected.clear(); }); return; }
              if (v == 'find') { _findAndReplace(); return; }
              if (v == 'rename') {
                final c = TextEditingController(text: _chapter.title);
                final next = await showDialog<String>(context: context, builder: (ctx)=>AlertDialog(title: const Text('Rename chapter'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Chapter name')), actions:[TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx,c.text.trim()), child: const Text('Save'))]));
                if (next != null && next.isNotEmpty) { setState(()=>_chapter.title = next); widget.onChanged(); }
                return;
              }
              if (v == 'copy') {
                final text = _chapter.blocks.map((b)=>b.text).join('\n\n');
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter copied')));
              }
              if (v == 'paste') {
                final data = await Clipboard.getData('text/plain');
                final text = data?.text ?? '';
                if (text.trim().isEmpty) return;
                _record();
                final parts = text.split(RegExp(r'\n\s*\n')).where((p)=>p.trim().isNotEmpty);
                _chapter.blocks..clear()..addAll(parts.map((p)=>Block(text:p.trim(), style: defaultStyleFor(_languageCode))));
                _controllers.clear();
                _activeIndex = _chapter.blocks.isEmpty ? null : 0;
                _touch();
              }
              if (v == 'selectall') { setState(() { _selectMode = true; _selected..clear()..addAll(List.generate(_chapter.blocks.length,(i)=>i)); }); }
              if (v == 'editall') { _showWholeChapterEditor(); }
              if (v.startsWith('type:')) { _addBlock(BlockType.values.byName(v.split(':')[1])); }
              if (v.startsWith('set:')) {
                final t = BlockType.values.byName(v.split(':')[1]);
                _record();
                for (final b in _scopeBlocks().isEmpty ? [_active].whereType<Block>() : _scopeBlocks()) { b.type = t; }
                _touch();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'save', child: Text('Save now')),
              if (compact) ...[
                PopupMenuItem(value: 'keyboard', child: Text(_showUrduKeyboard ? 'Hide Urdu keyboard' : 'Show Urdu keyboard')),
                PopupMenuItem(value: 'view', child: Text(_continuousView ? 'Block edit view' : 'Continuous writing view')),
                if (!_continuousView)
                  PopupMenuItem(value: 'selectmode', child: Text(_selectMode ? 'Exit select mode' : 'Select blocks')),
                const PopupMenuItem(value: 'find', child: Text('Find and replace')),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(value: 'rename', child: Text('Rename chapter')),
              const PopupMenuItem(value: 'copy', child: Text('Copy whole chapter')),
              const PopupMenuItem(value: 'paste', child: Text('Paste/replace whole chapter')),
              const PopupMenuItem(value: 'editall', child: Text('Edit whole chapter text')),
              const PopupMenuItem(value: 'selectall', child: Text('Select all blocks')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text('Insert block')),
              for (final t in BlockType.values) PopupMenuItem(value: 'type:${t.name}', child: Text('Insert ${t.label}')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text('Set selected/active as')),
              for (final t in BlockType.values) PopupMenuItem(value: 'set:${t.name}', child: Text(t.label)),
            ],
          ),
        ],
        bottom: _buildTabBar(),
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

  TabBar _buildTabBar() {
    final compact = MediaQuery.sizeOf(context).width < 700;
    const items = <MapEntry<IconData, String>>[
      MapEntry(Icons.edit_note, 'Write'),
      MapEntry(Icons.format_paint, 'Format'),
      MapEntry(Icons.visibility, 'Preview'),
      MapEntry(Icons.list_alt, 'Outline'),
      MapEntry(Icons.auto_awesome, 'AI'),
    ];
    return TabBar(
      controller: _tabs,
      isScrollable: !compact,
      labelPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 2)
          : null,
      tabs: [
        for (final item in items)
          Tab(
            icon: compact ? null : Icon(item.key),
            text: compact ? null : item.value,
            child: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.key, size: 18),
                      const SizedBox(height: 2),
                      Text(
                        item.value,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildEditorTabs() =>         TabBarView(
        controller: _tabs,
        children: [
          _buildWriteTab(),
          _buildFormatTab(),
          ChapterPreview(
            chapter: _chapter,
            languageCode: _languageCode,
            template: bookTemplateById(widget.book.templateId),
          ),
          _buildOutlineTab(),
          _buildAiTab(),
        ],
      );

  Widget _buildWriteTab() {
    final scheme = Theme.of(context).colorScheme;
    final blocks = _chapter.blocks;
    final activeStyle = _active?.style;
    return Column(
      children: [
        Material(
          color: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FontToolbar(style: activeStyle, onChanged: _applyStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _selected.isNotEmpty || activeStyle != null
                          ? () => _applyStyleToAll(
                              activeStyle ?? defaultStyleFor(_languageCode))
                          : null,
                      icon: const Icon(Icons.format_paint_outlined),
                      label: const Text('Apply to all blocks'),
                    ),
                    OutlinedButton.icon(onPressed: blocks.isEmpty ? null : _selectAll, icon: const Icon(Icons.select_all), label: const Text('Select all blocks')),
                    if (_selectMode || _selected.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear),
                        label: Text('Deselect ${_selected.length} paragraphs'),
                      ),
                  ],
                ),
                if (_selected.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_selected.length} blocks selected — font changes apply to selected blocks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: Column(children: [
            Expanded(child: blocks.isEmpty
              ? const Center(child: Text('Tap + to add a paragraph.'))
              : _continuousView ? _buildContinuousView(blocks)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: blocks.length,
                  itemBuilder: (context, i) => _BlockTile(
                    key: ValueKey('${blocks[i].id}_$_revision'),
                    block: blocks[i],
                    languageCode: _languageCode,
                    selected: _activeIndex == i,
                    checked: _selected.contains(i),
                    selectMode: _selectMode,
                    controller: _controllerFor(blocks[i]),
                    onFocus: () => setState(() => _activeIndex = i),
                    onToggleSelect: () => _toggleSelect(i),
                    onBeforeChange: _record,
                    onChanged: _touch,
                    onDelete: () => _deleteBlock(i),
                    onJoinPrevious: i == 0 ? null : () { _record(); _chapter.blocks[i - 1].text = '${_chapter.blocks[i - 1].text}\n${blocks[i].text}'.trim(); final removed=_chapter.blocks.removeAt(i); _controllers.remove(removed.id)?.dispose(); _activeIndex = i - 1; _touch(); },
                  ),
                )),
            if (_showUrduKeyboard) _buildUrduKeyboard(),
          ]),
        ),
      ],
    );
  }


  void _insertAtCursor(String text) {
    final idx = _activeIndex ?? ( _chapter.blocks.isNotEmpty ? 0 : -1);
    if (idx < 0 || idx >= _chapter.blocks.length) return;
    final block = _chapter.blocks[idx];
    final c = _controllerFor(block);
    final sel = c.selection;
    final start = sel.start >= 0 ? sel.start : c.text.length;
    final end = sel.end >= 0 ? sel.end : c.text.length;
    final next = c.text.replaceRange(start, end, text);
    _record();
    block.text = next;
    c.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: start + text.length));
    _touch();
  }

  Widget _buildUrduKeyboard() {
    const keys = ['آ','ا','ب','پ','ت','ٹ','ث','ج','چ','ح','خ','د','ڈ','ذ','ر','ڑ','ز','ژ','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ک','گ','ل','م','ن','ں','و','ؤ','ہ','ۂ','ھ','ء','ی','ئ','ے','ۃ','ً','ٌ','ٍ','َ','ُ','ِ','ّ','ْ','ٗ','ٔ','۔','،','؟','!',' ', '⌫'];
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children:[const Icon(Icons.keyboard), const SizedBox(width:8), const Text('Urdu keyboard'), const Spacer(), IconButton(onPressed: ()=>setState(()=>_showUrduKeyboard=false), icon: const Icon(Icons.close))]),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final k in keys)
              ActionChip(
                label: Text(k == ' ' ? 'Space' : k),
                onPressed: () {
                  if (k == '⌫') {
                    final idx = _activeIndex ?? 0;
                    if (idx < 0 || idx >= _chapter.blocks.length) return;
                    final c = _controllerFor(_chapter.blocks[idx]);
                    final sel = c.selection; final start = sel.start >= 0 ? sel.start : c.text.length; final end = sel.end >= 0 ? sel.end : c.text.length;
                    if (start == 0 && end == 0) return;
                    final s0 = start == end ? start - 1 : start;
                    final next = c.text.replaceRange(s0, end, '');
                    _record(); _chapter.blocks[idx].text = next; c.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: s0)); _touch();
                    return;
                  }
                  _insertAtCursor(k == ' ' ? ' ' : k);
                },
              ),
          ]),
        ]),
      ),
    );
  }


  Future<void> _showWholeChapterEditor() async {
    final c = TextEditingController(text: _chapter.blocks.map((b)=>b.text).join('\n\n'));
    final ok = await showDialog<bool>(context: context, builder: (ctx)=>AlertDialog(
      title: const Text('Edit whole chapter'),
      content: SizedBox(width: 700, height: 500, child: TextField(controller: c, maxLines: null, expands: true, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste or edit full chapter text...'))),
      actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')), FilledButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Apply'))],
    ));
    if (ok != true) return;
    _record();
    final parts = c.text.split(RegExp(r'\n\s*\n')).map((p)=>p.trim()).where((p)=>p.isNotEmpty).toList();
    _chapter.blocks..clear()..addAll(parts.isEmpty ? [Block(style: defaultStyleFor(_languageCode))] : parts.map((p)=>Block(text:p, style: defaultStyleFor(_languageCode))));
    _controllers.clear();
    _activeIndex = _chapter.blocks.isEmpty ? null : 0;
    _touch();
  }

  Widget _buildContinuousView(List<Block> blocks) {
    final template = bookTemplateById(widget.book.templateId);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              color: Color(template.surface),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < blocks.length; i++) _continuousBlock(blocks[i], i, template),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continuousBlock(Block block, int index, BookTemplate template) {
    final rtl = block.resolvedRtl(_languageCode);
    final s = block.style;
    final isHeading = block.type == BlockType.heading1 || block.type == BlockType.heading2 || block.type == BlockType.heading3;
    final size = switch (block.type) { BlockType.heading1 => s.fontSize+8, BlockType.heading2 => s.fontSize+5, BlockType.heading3 => s.fontSize+2, _ => s.fontSize };
    final style = TextStyle(
      fontFamily: s.fontFamily.isNotEmpty ? s.fontFamily : (isHeading ? template.headingFont : template.bodyFont),
      fontSize: size, height: s.lineHeight, letterSpacing: s.letterSpacing,
      fontWeight: isHeading || s.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: block.type == BlockType.quote || s.italic ? FontStyle.italic : FontStyle.normal,
      decoration: s.underline ? TextDecoration.underline : TextDecoration.none,
      color: s.color == 0xFF000000 ? Color(template.text) : resolvedTextColor(context, s.color),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: block.paragraphSpacing),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
            _record();
            final insert = index + 1;
            _chapter.blocks.insert(insert, Block(type: BlockType.paragraph, rtl: block.rtl, paragraphSpacing: block.paragraphSpacing, style: block.style.copyWith()));
            _activeIndex = insert;
            _touch();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace && block.text.isEmpty && index > 0) {
            _record();
            final removed = _chapter.blocks.removeAt(index);
            _controllers.remove(removed.id)?.dispose();
            _activeIndex = index - 1;
            _touch();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controllerFor(block),
          onTap: () => setState(() => _activeIndex = index),
          onChanged: (v) { if (block.text == v) return; _record(); block.text = v; _touch(); },
          maxLines: null,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          textAlign: block.type == BlockType.centered ? TextAlign.center : (rtl ? TextAlign.right : TextAlign.left),
          style: style,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: index == 0 ? 'Write here...' : '',
            contentPadding: EdgeInsets.symmetric(vertical: isHeading ? 8 : 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatTab() {
    final template = bookTemplateById(widget.book.templateId);
    final scopeBlocks = _scopeBlocks();
    final sampleBlock = scopeBlocks.isNotEmpty ? scopeBlocks.first : null;
    final targetStyle = sampleBlock?.style ?? defaultStyleFor(_languageCode);
    final canFormat = scopeBlocks.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Whole page & template',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('template_${widget.book.templateId}'),
                  initialValue: widget.book.templateId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Book template'),
                  selectedItemBuilder: (_) => [
                    for (final t in kBookTemplates)
                      Text(t.name, overflow: TextOverflow.ellipsis),
                  ],
                  items: [
                    for (final t in kBookTemplates)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.name} — ${t.description}'),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    _applyTemplate(bookTemplateById(id), wholeBook: true);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: canFormat
                          ? () => _applyStyleToAll(targetStyle)
                          : null,
                      icon: const Icon(Icons.format_paint),
                      label: const Text('Apply font to whole chapter'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _applyTemplate(template, wholeBook: true),
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Apply template to entire book'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _applyTemplate(template, wholeBook: false),
                      icon: const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('This chapter only'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecting a template restyles every chapter. Font controls below follow the chosen scope.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canFormat
                      ? 'Formatting ${scopeBlocks.length} paragraph(s)'
                      : 'Nothing to format yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children:[
                  ChoiceChip(label: const Text('Selected paragraphs'), selected: _applyScope=='selected', onSelected: (_)=>setState(()=>_applyScope='selected')),
                  ChoiceChip(label: const Text('This chapter'), selected: _applyScope=='chapter', onSelected: (_)=>setState(()=>_applyScope='chapter')),
                  ChoiceChip(label: const Text('Entire book'), selected: _applyScope=='book', onSelected: (_)=>setState(()=>_applyScope='book')),
                ]),
                const SizedBox(height: 12),
                if (!canFormat)
                  const Text('Add or select a paragraph in Write, or choose This chapter / Entire book.')
                else ...[
                  DropdownButtonFormField<BlockType>(
                    key: ValueKey('blocktype_${_applyScope}_${sampleBlock?.type}'),
                    initialValue: sampleBlock?.type ?? BlockType.paragraph,
                    decoration: const InputDecoration(labelText: 'Block type'),
                    items: [for (final type in BlockType.values) DropdownMenuItem(value: type, child: Text(type.label))],
                    onChanged: (type) { if (type == null) return; _record(); for (final b in _scopeBlocks()) { b.type = type; } _touch(); },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<bool?>(
                    key: ValueKey('direction_${_applyScope}_${sampleBlock?.rtl}'),
                    initialValue: sampleBlock?.rtl,
                    decoration: const InputDecoration(labelText: 'Paragraph direction'),
                    items: const [DropdownMenuItem(value: null, child: Text('Auto (book language)')), DropdownMenuItem(value: true, child: Text('Right to left')), DropdownMenuItem(value: false, child: Text('Left to right'))],
                    onChanged: (v) { _record(); for (final b in _scopeBlocks()) { b.rtl = v; } _touch(); },
                  ),
                  const SizedBox(height: 8),
                  Row(children:[const Text('Paragraph spacing'), Expanded(child: Slider(value: (sampleBlock?.paragraphSpacing ?? 8).clamp(0,32).toDouble(), min:0, max:32, divisions:16, onChanged: (v){ _record(); for (final b in _scopeBlocks()) { b.paragraphSpacing = v; } _touch(); })), Text('${(sampleBlock?.paragraphSpacing ?? 8).round()} pt')]),
                  const Divider(height: 24),
                  FontToolbar(style: targetStyle, onChanged: _applyStyle),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyTemplate(BookTemplate template, {required bool wholeBook}) {
    final chapters = wholeBook ? widget.book.allChapters : <Chapter>[_chapter];
    if (!chapters.any((chapter) => chapter.blocks.isNotEmpty)) return;
    _record();
    for (final chapter in chapters) {
      for (final block in chapter.blocks) {
        final isHeading = block.type == BlockType.heading1 ||
            block.type == BlockType.heading2 ||
            block.type == BlockType.heading3;
        final size = switch (block.type) {
          BlockType.heading1 => template.bodySize + 8,
          BlockType.heading2 => template.bodySize + 5,
          BlockType.heading3 => template.bodySize + 2,
          _ => template.bodySize,
        };
        block.style = block.style.copyWith(
          fontFamily: isHeading ? template.headingFont : template.bodyFont,
          fontSize: size.toDouble(),
          lineHeight: template.lineHeight,
          color: template.text,
        );
      }
    }
    widget.book.templateId = template.id;
    _touch();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${template.name} applied to ${wholeBook ? 'entire book' : 'this chapter'}',
          ),
        ),
      );
    }
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
          Expanded(
            child: ChapterPreview(
              chapter: _chapter,
              languageCode: _languageCode,
              template: bookTemplateById(widget.book.templateId),
            ),
          ),
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
                Chip(label: Text(languageName(_languageCode)), backgroundColor: Colors.white, labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
          for (var i = 0; i < widget.chapters.length; i++)
            Builder(builder: (context) {
              final chapter = widget.chapters[i];
              final sameAsBook = chapter.title.trim() == widget.book.title.trim() || chapter.title.trim().isEmpty;
              final label = sameAsBook ? 'Chapter ${i + 1}' : chapter.title;
              return ListTile(
                selected: chapter.id == _chapter.id,
                leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                title: Text(label),
                subtitle: sameAsBook ? Text(chapter.title.isEmpty ? 'Untitled chapter' : 'Same as book title') : null,
                onTap: () => _selectChapter(chapter),
              );
            }),
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
  final bool checked;
  final bool selectMode;
  final TextEditingController controller;
  final VoidCallback onFocus;
  final VoidCallback onToggleSelect;
  final VoidCallback onBeforeChange;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onJoinPrevious;

  const _BlockTile({
    super.key,
    required this.block,
    required this.languageCode,
    required this.selected,
    required this.checked,
    required this.selectMode,
    required this.controller,
    required this.onFocus,
    required this.onToggleSelect,
    required this.onBeforeChange,
    required this.onChanged,
    required this.onDelete,
    this.onJoinPrevious,
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
        color: checked
            ? scheme.secondaryContainer.withValues(alpha: 0.45)
            : selected
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : null,
        border: Border.all(
          color: checked
              ? scheme.secondary
              : selected
                  ? scheme.primary
                  : scheme.outlineVariant,
          width: checked || selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (selectMode)
                Checkbox(value: checked, onChanged: (_) => onToggleSelect()),
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
              if (checked)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Chip(label: Text('Selected'), visualDensity: VisualDensity.compact),
                ),
              const Spacer(),
              PopupMenuButton<bool?>(
                tooltip: 'Direction', initialValue: block.rtl,
                onSelected: (v){ onBeforeChange(); block.rtl=v; onChanged(); },
                itemBuilder: (_) => const [PopupMenuItem(value:null, child: Text('Auto')), PopupMenuItem(value:true, child: Text('RTL')), PopupMenuItem(value:false, child: Text('LTR'))],
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(rtl?Icons.format_textdirection_r_to_l:Icons.format_textdirection_l_to_r)),
              ),
              IconButton(tooltip:'Join with previous', icon:const Icon(Icons.merge_type), onPressed:onJoinPrevious),
              IconButton(tooltip:'Split paragraph', icon:const Icon(Icons.call_split), onPressed:(){ final parts=block.text.split('\n'); if(parts.length<2) return; onBeforeChange(); block.text=parts.first; onChanged(); }),
              IconButton(tooltip:'Delete block', icon: const Icon(Icons.delete_outline), onPressed:onDelete),
            ],
          ),
          TextField(
            controller: controller,
            onTap: selectMode ? onToggleSelect : onFocus,
            onChanged: (v) { if (block.text == v) return; onBeforeChange(); block.text = v; onChanged(); },
            maxLines: null,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: block.type == BlockType.centered ? TextAlign.center : (rtl ? TextAlign.right : TextAlign.left),
            style: textStyle,
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write here...'),
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
