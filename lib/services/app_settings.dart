import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum AppThemeColor {
  teal('Teal', 0xFF0F766E),
  purple('Purple', 0xFF7E22CE),
  blue('Blue', 0xFF1D4ED8),
  amber('Amber', 0xFFB45309),
  rose('Rose', 0xFFBE185D),
  green('Green', 0xFF15803D);

  final String label;
  final int color;
  const AppThemeColor(this.label, this.color);
}

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  const AppLanguage(this.code, this.name, this.nativeName);
}

const List<AppLanguage> kAppLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('ur', 'Urdu', 'اردو'),
  AppLanguage('ar', 'Arabic', 'العربية'),
  AppLanguage('hi', 'Hindi', 'हिन्दी'),
  AppLanguage('fa', 'Persian', 'فارسی'),
];

class AppSettings {
  final AppThemeMode themeMode;
  final AppThemeColor themeColor;
  final String localeCode;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.themeColor = AppThemeColor.teal,
    this.localeCode = 'en',
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppThemeColor? themeColor,
    String? localeCode,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        themeColor: themeColor ?? this.themeColor,
        localeCode: localeCode ?? this.localeCode,
      );

  ThemeMode get flutterThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Locale get locale => Locale(localeCode);

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'themeColor': themeColor.name,
        'localeCode': localeCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        themeColor: AppThemeColor.values.firstWhere(
          (c) => c.name == json['themeColor'],
          orElse: () => AppThemeColor.teal,
        ),
        localeCode: json['localeCode'] as String? ?? 'en',
      );
}

class AppSettingsStore {
  static const _key = 'urdu_book_studio.app.v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}

class AppSettingsController extends ChangeNotifier {
  AppSettings _settings;
  final AppSettingsStore _store;

  AppSettingsController(this._settings, [AppSettingsStore? store])
      : _store = store ?? AppSettingsStore();

  AppSettings get settings => _settings;

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _store.save(settings);
  }
}
