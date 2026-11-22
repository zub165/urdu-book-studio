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

class BookTemplate {
  final String id;
  final String name;
  final String description;
  final int background;
  final int surface;
  final int text;
  final int accent;
  final String bodyFont;
  final String headingFont;
  final double bodySize;
  final double lineHeight;

  const BookTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.background,
    required this.surface,
    required this.text,
    required this.accent,
    required this.bodyFont,
    required this.headingFont,
    required this.bodySize,
    required this.lineHeight,
  });
}

const List<BookTemplate> kBookTemplates = [
  BookTemplate(
    id: 'classic',
    name: 'Classic',
    description: 'Clean white pages with dark text',
    background: 0xFFF3F4F6,
    surface: 0xFFFFFFFF,
    text: 0xFF111827,
    accent: 0xFF0F766E,
    bodyFont: 'Roboto',
    headingFont: 'Roboto',
    bodySize: 16,
    lineHeight: 1.7,
  ),
  BookTemplate(
    id: 'urdu_nastaliq',
    name: 'Urdu Nastaliq',
    description: 'Warm paper with Nastaliq typography',
    background: 0xFFF7F1E6,
    surface: 0xFFFFFBF4,
    text: 0xFF2B2118,
    accent: 0xFF8B5E34,
    bodyFont: 'Noto Nastaliq Urdu',
    headingFont: 'Noto Nastaliq Urdu',
    bodySize: 20,
    lineHeight: 2.1,
  ),
  BookTemplate(
    id: 'naskh',
    name: 'Naskh',
    description: 'Clear Naskh for Arabic-script reading',
    background: 0xFFF8FAFC,
    surface: 0xFFFFFFFF,
    text: 0xFF1F2937,
    accent: 0xFF1D4ED8,
    bodyFont: 'Noto Naskh Arabic',
    headingFont: 'Noto Naskh Arabic',
    bodySize: 18,
    lineHeight: 1.9,
  ),
  BookTemplate(
    id: 'sepia',
    name: 'Sepia',
    description: 'Soft sepia for long reading sessions',
    background: 0xFFF1E4C8,
    surface: 0xFFFDF6E3,
    text: 0xFF3F2F1B,
    accent: 0xFF92400E,
    bodyFont: 'Roboto',
    headingFont: 'Roboto',
    bodySize: 16,
    lineHeight: 1.8,
  ),
  BookTemplate(
    id: 'night',
    name: 'Night',
    description: 'Dark preview with light text',
    background: 0xFF111827,
    surface: 0xFF1F2937,
    text: 0xFFF9FAFB,
    accent: 0xFF2DD4BF,
    bodyFont: 'Roboto',
    headingFont: 'Roboto',
    bodySize: 16,
    lineHeight: 1.75,
  ),
];

BookTemplate bookTemplateById(String? id) => kBookTemplates.firstWhere(
      (t) => t.id == id,
      orElse: () => kBookTemplates.first,
    );
