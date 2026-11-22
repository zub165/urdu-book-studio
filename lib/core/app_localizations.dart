import 'package:flutter/widgets.dart';

import 'app_strings.dart';

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supported.contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
