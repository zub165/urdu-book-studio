import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urdu_book_studio/editor/chapter_editor.dart';
import 'package:urdu_book_studio/main.dart';
import 'package:urdu_book_studio/models/book.dart';
import 'package:urdu_book_studio/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('library screen starts empty', (WidgetTester tester) async {
    await tester.pumpWidget(UrduBookStudioApp(
      controller: AppSettingsController(const AppSettings()),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('No books yet. Tap "New book" or import a file.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('editor shows all tabs, side menu and live preview',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final book = Book.create(
      title: 'اردو کتاب',
      author: 'ملک',
      languageCode: 'ur',
    );
    await tester.pumpWidget(MaterialApp(
      home: ChapterEditor(
        book: book,
        chapter: book.chapters.first,
        chapters: book.chapters,
        onChanged: () {},
      ),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Write', 'Format', 'Preview', 'Outline', 'AI']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Live preview'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Insert block'), findsOneWidget);
    expect(find.text('Find and replace'), findsWidgets);
  });

  testWidgets('can create a book and open the editor', (WidgetTester tester) async {
    await tester.pumpWidget(UrduBookStudioApp(
      controller: AppSettingsController(const AppSettings()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New book'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ).first,
      'Test Book',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Open "Chapter 1"'));
    await tester.pumpAndSettle();

    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Write here...'), findsWidgets);
  });

  testWidgets('editor text stays visible in dark theme',
      (WidgetTester tester) async {
    final book = Book.create(
      title: 'اردو کتاب',
      author: 'ملک',
      languageCode: 'ur',
    );
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: ChapterEditor(
        book: book,
        chapter: book.chapters.first,
        chapters: book.chapters,
        onChanged: () {},
      ),
    ));
    await tester.pumpAndSettle();

    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(field.style.color, isNot(Colors.black));
    expect(field.style.color, isNot(Colors.transparent));
  });
}
