import 'package:flutter/material.dart';

import 'library/library_screen.dart';

void main() {
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
  runApp(const UrduBookStudioApp());
}

class UrduBookStudioApp extends StatelessWidget {
  const UrduBookStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urdu Book Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const LibraryScreen(),
    );
  }
}
