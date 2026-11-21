import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/book.dart';

/// Controls for the selected block. Disabled when no block is selected.
class FontToolbar extends StatelessWidget {
  final TextStyleData? style;
  final ValueChanged<TextStyleData> onChanged;

  const FontToolbar({super.key, required this.style, required this.onChanged});

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
      ],
    );
  }
}
