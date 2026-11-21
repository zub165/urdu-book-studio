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

String languageName(String code) => kLanguages
    .firstWhere((l) => l.code == code, orElse: () => LanguageOption(code, code))
    .name;

/// Fonts available in the editor. The first two are bundled in assets/fonts.
const List<String> kFonts = [
  'Noto Nastaliq Urdu',
  'Noto Naskh Arabic',
  'Roboto',
];
