import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/book.dart';
import '../services/ai_service.dart';
import 'font_toolbar.dart';

class AiInsertResult {
  final List<Block> blocks;

  const AiInsertResult(this.blocks);
}

class AiSettingsDialog extends StatefulWidget {
  final AiSettings settings;

  const AiSettingsDialog({super.key, required this.settings});

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  late AiProvider _provider;
  late TextEditingController _key;
  late TextEditingController _model;
  late TextEditingController _backendUrl;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.settings.provider;
    _key = TextEditingController(text: widget.settings.apiKey);
    _model = TextEditingController(text: widget.settings.model);
    _backendUrl = TextEditingController(text: widget.settings.backendUrl);
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _backendUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI settings'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AiProvider>(
              initialValue: _provider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                for (final provider in AiProvider.values)
                  DropdownMenuItem(
                    value: provider,
                    child: Text(provider.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _provider = value;
                  _model.text = value.defaultModel;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_provider == AiProvider.ollama)
              TextField(
                controller: _backendUrl,
                onChanged: (_) => setState(() => _testResult = null),
                decoration: const InputDecoration(
                  labelText: 'Ollama URL',
                  helperText: 'Desktop/mobile: http://localhost:11434. Web: public HTTPS Ollama proxy with CORS.',
                ),
              ),
            if (_provider == AiProvider.ollama && kIsWeb && _backendUrl.text.trim().startsWith('http://'))
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Web builds may block local HTTP Ollama; use a public HTTPS Ollama proxy with CORS, or run desktop app.', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
            if (_provider == AiProvider.ollama) const SizedBox(height: 8),
            if (_provider == AiProvider.ollama)
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : () async {
                    final settings = AiSettings(provider: _provider, apiKey: _key.text.trim(), model: _model.text.trim().isEmpty ? _provider.defaultModel : _model.text.trim(), backendUrl: _backendUrl.text.trim());
                    setState(() { _testing = true; _testResult = null; });
                    try {
                      final text = await AiService().generate('Reply with the word OK only.', settings);
                      if (!mounted) return;
                      setState(() { _testOk = true; _testResult = 'Connected: ${text.trim()}'; });
                    } catch (e) {
                      if (!mounted) return;
                      setState(() { _testOk = false; _testResult = 'Failed: $e'; });
                    } finally {
                      if (mounted) setState(() => _testing = false);
                    }
                  },
                  icon: _testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
                  label: const Text('Test connection'),
                ),
              ]),
            if (_testResult != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_testResult!, style: TextStyle(color: _testOk ? Colors.green : Theme.of(context).colorScheme.error))),
            if (_provider == AiProvider.ollama) const SizedBox(height: 8),
            TextField(
              controller: _key,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _provider == AiProvider.ollama
                    ? 'API token (optional)'
                    : 'API key',
                helperText: 'Stored only on this device',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model'),
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
            AiSettings(
              provider: _provider,
              apiKey: _key.text.trim(),
              model: _model.text.trim().isEmpty
                  ? _provider.defaultModel
                  : _model.text.trim(),
              backendUrl: _backendUrl.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AiStyleControls extends StatefulWidget {
  final String languageCode;

  const _AiStyleControls({super.key, required this.languageCode});

  @override
  State<_AiStyleControls> createState() => _AiStyleControlsState();
}

class _AiStyleControlsState extends State<_AiStyleControls> {
  late String _font;
  late double _size;
  late int _color;

  @override
  void initState() {
    super.initState();
    final style = defaultStyleFor(widget.languageCode);
    _font = style.fontFamily;
    _size = style.fontSize;
    _color = 0xFF000000;
  }

  TextStyleData get style => TextStyleData(
        fontFamily: _font,
        fontSize: _size,
        color: _color,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Template style: '),
            DropdownButton<String>(
              value: _font,
              items: [
                for (final f in kFonts)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _font = v);
              },
            ),
            const Spacer(),
            Text('${_size.round()} pt'),
          ],
        ),
        Slider(
          value: _size.clamp(10.0, 48.0).toDouble(),
          min: 10,
          max: 48,
          divisions: 38,
          onChanged: (v) => setState(() => _size = v.roundToDouble()),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final (name, value) in kTextColors)
              InkWell(
                onTap: () => setState(() => _color = value),
                child: Tooltip(
                  message: name,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == value ? Colors.blue : Colors.black26,
                        width: _color == value ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class TranslateDialog extends StatefulWidget {
  final AiSettings settings;
  final String bookLanguage;

  const TranslateDialog({
    super.key,
    required this.settings,
    required this.bookLanguage,
  });

  @override
  State<TranslateDialog> createState() => _TranslateDialogState();
}

class _TranslateDialogState extends State<TranslateDialog> {
  final _text = TextEditingController();
  final _styleKey = GlobalKey<_AiStyleControlsState>();
  String _source = 'en';
  late String _target;
  BlockType _template = BlockType.paragraph;
  bool _urduDigits = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _target = widget.bookLanguage;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = AiService();
      try {
        final translated = await service.translate(
          text: _text.text.trim(),
          sourceLanguage: translationLanguageName(_source),
          targetLanguage: translationLanguageName(_target),
          settings: widget.settings,
          urduDigits: _urduDigits,
        );
        final style = _styleKey.currentState?.style ?? defaultStyleFor(_target);
        final blocks = translated
            .split(RegExp(r'\n\s*\n'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .map((part) => Block(type: _template, text: part, style: style))
            .toList();
        if (!mounted) return;
        Navigator.pop(context, AiInsertResult(blocks));
      } finally {
        service.dispose();
      }
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI translate'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _text,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Text to translate',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _source,
                      decoration: const InputDecoration(labelText: 'From'),
                      items: [
                        for (final l in kTranslationLanguages)
                          DropdownMenuItem(value: l.code, child: Text(l.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _source = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _target,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: [
                        for (final l in kTranslationLanguages)
                          DropdownMenuItem(value: l.code, child: Text(l.name)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _target = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BlockType>(
                initialValue: _template,
                decoration: const InputDecoration(labelText: 'Insert as template'),
                items: [
                  for (final type in BlockType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _template = v);
                },
              ),
              const SizedBox(height: 12),
              _AiStyleControls(key: _styleKey, languageCode: _target),
              SwitchListTile(
                value: _urduDigits,
                onChanged: (v) => setState(() => _urduDigits = v),
                title: const Text('Use Urdu digits (۰-۹)'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Translate and insert'),
        ),
      ],
    );
  }
}

class OutlineDialog extends StatefulWidget {
  final AiSettings settings;
  final String languageCode;

  const OutlineDialog({
    super.key,
    required this.settings,
    required this.languageCode,
  });

  @override
  State<OutlineDialog> createState() => _OutlineDialogState();
}

class _OutlineDialogState extends State<OutlineDialog> {
  final _topic = TextEditingController();
  final _styleKey = GlobalKey<_AiStyleControlsState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_topic.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = AiService();
      try {
        final outline = await service.outline(
          topic: _topic.text.trim(),
          language: translationLanguageName(widget.languageCode),
          settings: widget.settings,
        );
        final style = _styleKey.currentState?.style ??
            defaultStyleFor(widget.languageCode);
        final blocks = <Block>[];
        for (final rawLine in outline.split('\n')) {
          final line = rawLine.trim();
          if (line.isEmpty) continue;
          final prefix = line.length >= 3 ? line.substring(0, 3).toUpperCase() : '';
          if (prefix == 'H1:') {
            blocks.add(Block(
              type: BlockType.heading1,
              text: line.substring(3).trim(),
              style: style.copyWith(bold: true, fontSize: style.fontSize + 4),
            ));
          } else if (prefix == 'H2:') {
            blocks.add(Block(
              type: BlockType.heading2,
              text: line.substring(3).trim(),
              style: style.copyWith(bold: true, fontSize: style.fontSize + 2),
            ));
          } else {
            final text = prefix == 'P: '
                ? line.substring(3).trim()
                : line.replaceFirst(RegExp(r'^(P:)\s*', caseSensitive: false), '');
            blocks.add(Block(type: BlockType.paragraph, text: text, style: style));
          }
        }
        if (blocks.isEmpty) {
          throw const AiException('No outline lines were produced.');
        }
        if (!mounted) return;
        Navigator.pop(context, AiInsertResult(blocks));
      } finally {
        service.dispose();
      }
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI heading outline'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _topic,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Book or chapter topic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _AiStyleControls(key: _styleKey, languageCode: widget.languageCode),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Generate and insert'),
        ),
      ],
    );
  }
}
