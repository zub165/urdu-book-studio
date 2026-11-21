import 'package:flutter/material.dart';

import 'library/library_screen.dart';

void main() {
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
      ),
      home: const LibraryScreen(),
    );
  }
}
