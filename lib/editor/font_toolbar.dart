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
class FontToolbar extends StatelessWidget {
  final TextStyleData? style;
  final ValueChanged<TextStyleData> onChanged;

  const FontToolbar({super.key, required this.style, required this.onChanged});

  Future<void> _pickColor(BuildContext context, TextStyleData current) async {
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
    if (color != null) onChanged(current.copyWith(color: color));
  }

  @override
  Widget build(BuildContext context) {
    final enabled = style != null;
    final current = style ?? const TextStyleData();

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: kFonts.contains(current.fontFamily)
                ? current.fontFamily
                : kFonts.first,
            isDense: true,
            decoration: const InputDecoration(labelText: 'Font', isDense: true),
            items: [
              for (final f in kFonts)
                DropdownMenuItem(
                  value: f,
                  child: Text(f, style: TextStyle(fontFamily: f)),
                ),
            ],
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged(current.copyWith(fontFamily: v));
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
                      ? (v) => onChanged(current.copyWith(fontSize: v.roundToDouble()))
                      : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          child: Row(
            children: [
              const Text('Line'),
              Expanded(
                child: Slider(
                  value: current.lineHeight.clamp(1.0, 3.0).toDouble(),
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  onChanged: enabled
                      ? (v) => onChanged(current.copyWith(lineHeight: double.parse(v.toStringAsFixed(1))))
                      : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          child: Row(
            children: [
              Text('Space ${current.letterSpacing.toStringAsFixed(1)}'),
              Expanded(
                child: Slider(
                  value: current.letterSpacing.clamp(0.0, 5.0).toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 20,
                  onChanged: enabled
                      ? (v) => onChanged(current.copyWith(
                          letterSpacing: double.parse(v.toStringAsFixed(1))))
                      : null,
                ),
              ),
            ],
          ),
        ),
        ToggleButtons(
          isSelected: [current.bold, current.italic, current.underline],
          onPressed: enabled
              ? (i) {
                  switch (i) {
                    case 0:
                      onChanged(current.copyWith(bold: !current.bold));
                    case 1:
                      onChanged(current.copyWith(italic: !current.italic));
                    case 2:
                      onChanged(current.copyWith(underline: !current.underline));
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
          icon: Icon(Icons.format_color_text, color: Color(current.color)),
          onPressed: enabled ? () => _pickColor(context, current) : null,
        ),
      ],
    );
  }
}
