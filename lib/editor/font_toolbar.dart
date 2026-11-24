import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/book.dart';

const List<(String, int)> kTextColors = [
  ('Black', 0xFF000000),
  ('White', 0xFFFFFFFF),
  ('Dark red', 0xFFB91C1C),
  ('Red', 0xFFEF4444),
  ('Orange', 0xFFF97316),
  ('Gold', 0xFFEAB308),
  ('Green', 0xFF15803D),
  ('Teal', 0xFF0F766E),
  ('Blue', 0xFF1D4ED8),
  ('Purple', 0xFF7E22CE),
  ('Gray', 0xFF6B7280),
];

/// Controls for the selected block. Disabled when no block is selected.
class FontToolbar extends StatefulWidget {
  final TextStyleData? style;
  final ValueChanged<TextStyleData> onChanged;

  const FontToolbar({super.key, required this.style, required this.onChanged});

  @override
  State<FontToolbar> createState() => _FontToolbarState();
}

class _FontToolbarState extends State<FontToolbar> {
  late TextStyleData _current;

  @override
  void initState() {
    super.initState();
    _current = widget.style ?? const TextStyleData();
  }

  @override
  void didUpdateWidget(FontToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style) {
      _current = widget.style ?? const TextStyleData();
    }
  }

  void _apply(TextStyleData next) {
    setState(() => _current = next);
    widget.onChanged(next);
  }

  Future<void> _pickColor(BuildContext context) async {
    final color = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Text color'),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (name, value) in kTextColors)
                InkWell(
                  onTap: () => Navigator.pop(ctx, value),
                  child: Tooltip(
                    message: name,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    if (color != null) _apply(_current.copyWith(color: color));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.style != null;
    final current = _current;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey('font_${current.fontFamily}'),
            initialValue: kFonts.contains(current.fontFamily)
                ? current.fontFamily
                : kFonts.first,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Font', isDense: true),
            selectedItemBuilder: (_) => [
              for (final f in kFonts)
                Text(
                  f,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: f),
                ),
            ],
            items: [
              for (final f in kFonts)
                DropdownMenuItem(
                  value: f,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children:[
                    Text(f, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: f)),
                    Text(f.contains('Nastaliq') ? 'یہ ایک نمونہ جملہ ہے' : 'Sample Aa Bb', style: TextStyle(fontFamily: f, fontSize: 11)),
                  ]),
                ),
            ],
            onChanged: enabled
                ? (v) {
                    if (v != null) _apply(current.copyWith(fontFamily: v));
                  }
                : null,
          ),
        ),
        SizedBox(
          width: 220,
          child: Row(
            children: [
              Text('Size ${current.fontSize.round()}'),
              Expanded(
                child: Slider(
                  value: current.fontSize.clamp(10.0, 48.0).toDouble(),
                  min: 10,
                  max: 48,
                  divisions: 38,
                  onChanged: enabled
                      ? (v) => _apply(current.copyWith(fontSize: v.roundToDouble()))
                      : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: Row(children: [
            Expanded(flex:0, child: Text('Line ${current.lineHeight.toStringAsFixed(1)}x', overflow: TextOverflow.ellipsis)),
            Expanded(child: Slider(value: current.lineHeight.clamp(1.0, 3.0).toDouble(), min: 1.0, max: 3.0, divisions: 20,
              onChanged: enabled ? (v) => _apply(current.copyWith(lineHeight: double.parse(v.toStringAsFixed(1)))) : null)),
          ]),
        ),
        SizedBox(
          width: 260,
          child: Row(children: [
            Expanded(flex:0, child: Text('Letter ${current.letterSpacing.toStringAsFixed(1)}', overflow: TextOverflow.ellipsis)),
            Expanded(child: Slider(value: current.letterSpacing.clamp(0.0, 5.0).toDouble(), min: 0, max: 5, divisions: 50,
              onChanged: enabled ? (v) => _apply(current.copyWith(letterSpacing: double.parse(v.toStringAsFixed(1)))) : null)),
          ]),
        ),
        ToggleButtons(
          isSelected: [current.bold, current.italic, current.underline],
          onPressed: enabled
              ? (i) {
                  switch (i) {
                    case 0:
                      _apply(current.copyWith(bold: !current.bold));
                    case 1:
                      _apply(current.copyWith(italic: !current.italic));
                    case 2:
                      _apply(current.copyWith(underline: !current.underline));
                  }
                }
              : null,
          children: const [
            Tooltip(message: 'Bold', child: Icon(Icons.format_bold)),
            Tooltip(message: 'Italic', child: Icon(Icons.format_italic)),
            Tooltip(message: 'Underline', child: Icon(Icons.format_underlined)),
          ],
        ),
        IconButton(
          tooltip: 'Text color',
          icon: Icon(Icons.format_color_text,
              color: resolvedTextColor(context, current.color)),
          onPressed: enabled ? () => _pickColor(context) : null,
        ),
      ],
    );
  }
}
