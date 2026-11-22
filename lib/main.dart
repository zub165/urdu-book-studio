import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_localizations.dart';
import 'core/app_strings.dart';
import 'library/library_screen.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade900,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${details.exception}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  final settings = await AppSettingsStore().load();
  runApp(UrduBookStudioApp(controller: AppSettingsController(settings)));
}

class UrduBookStudioApp extends StatelessWidget {
  final AppSettingsController controller;
  const UrduBookStudioApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final settings = controller.settings;
          final seed = Color(settings.themeColor.color);
            final systemBrightness = MediaQuery.platformBrightnessOf(context);
            return MaterialApp(
              title: 'Book Writer & Publisher',
              debugShowCheckedModeBanner: false,
              locale: settings.locale,
              supportedLocales: [for (final code in AppStrings.supported) Locale(code)],
              localizationsDelegates: const [
                AppStringsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: settings.themeData(systemBrightness),
              darkTheme: settings.themeMode == AppThemeMode.system
                  ? ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark)
                  : settings.themeData(systemBrightness),
              themeMode: settings.themeMode == AppThemeMode.sepia ? ThemeMode.light : settings.flutterThemeMode,
              home: const LibraryScreen(),
            );
        },
      ),
    );
  }
}
