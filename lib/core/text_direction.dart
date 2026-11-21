/// Language codes written right-to-left.
const Set<String> rtlLanguageCodes = {
  'ur', 'ar', 'fa', 'ps', 'sd', 'ku', 'he', 'yi', 'dv', 'ug',
};

/// True when the language (e.g. "ur", "ur-PK") is right-to-left.
bool isRtlLanguage(String languageCode) {
  final primary = languageCode.split(RegExp('[-_]')).first.toLowerCase();
  return rtlLanguageCodes.contains(primary);
}

/// Converts Western digits to Extended Arabic-Indic digits used in Urdu.
String toUrduDigits(String input) {
  const western = '0123456789';
  const urdu = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final index = western.indexOf(ch);
    buffer.write(index >= 0 ? urdu[index] : ch);
  }
  return buffer.toString();
}
