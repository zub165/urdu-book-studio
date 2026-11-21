import 'package:flutter/material.dart';

class LanguageOption {
  final String code;
  final String name;
  const LanguageOption(this.code, this.name);
}

/// Languages offered when creating a book. Urdu is listed first.
const List<LanguageOption> kLanguages = [
  LanguageOption('ur', 'Urdu - اردو'),
  LanguageOption('en', 'English'),
  LanguageOption('ar', 'Arabic - العربية'),
  LanguageOption('fa', 'Persian - فارسی'),
  LanguageOption('ps', 'Pashto - پښتو'),
  LanguageOption('sd', 'Sindhi - سنڌي'),
  LanguageOption('hi', 'Hindi - हिन्दी'),
  LanguageOption('pa', 'Punjabi - ਪੰਜਾਬੀ'),
  LanguageOption('he', 'Hebrew - עברית'),
  LanguageOption('fr', 'French'),
  LanguageOption('es', 'Spanish'),
];

const List<LanguageOption> kTranslationLanguages = [
  LanguageOption('en', 'English'),
  LanguageOption('ur', 'Urdu'),
  LanguageOption('ar', 'Arabic'),
  LanguageOption('fa', 'Persian'),
  LanguageOption('ps', 'Pashto'),
  LanguageOption('sd', 'Sindhi'),
  LanguageOption('hi', 'Hindi'),
  LanguageOption('pa', 'Punjabi'),
  LanguageOption('he', 'Hebrew'),
  LanguageOption('fr', 'French'),
  LanguageOption('es', 'Spanish'),
  LanguageOption('de', 'German'),
];

String languageName(String code) => kLanguages
    .firstWhere((l) => l.code == code, orElse: () => LanguageOption(code, code))
    .name;

String translationLanguageName(String code) => kTranslationLanguages
    .firstWhere((l) => l.code == code, orElse: () => LanguageOption(code, code))
    .name;

const List<int> kLanguagePalette = [
  0xFF0F766E,
  0xFF7E22CE,
  0xFFB45309,
  0xFF1D4ED8,
  0xFFBE185D,
  0xFF15803D,
  0xFFC2410C,
  0xFF4338CA,
];

Color languageColor(String code) {
  final sum = code.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return Color(kLanguagePalette[sum % kLanguagePalette.length]);
}

Color resolvedTextColor(BuildContext context, int argb) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark && argb == 0xFF000000) {
    return theme.colorScheme.onSurface;
  }
  if (theme.brightness == Brightness.light && argb == 0xFFFFFFFF) {
    return theme.colorScheme.onSurface;
  }
  return Color(argb);
}

/// Fonts available in the editor. The first two are bundled in assets/fonts.
const List<String> kFonts = [
  'Noto Nastaliq Urdu',
  'Noto Naskh Arabic',
  'Roboto',
];
