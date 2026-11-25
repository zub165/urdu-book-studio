import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urdu_book_studio/core/constants.dart';
import 'package:urdu_book_studio/editor/chapter_editor.dart';
import 'package:urdu_book_studio/editor/font_toolbar.dart';
import 'package:urdu_book_studio/main.dart';
import 'package:urdu_book_studio/models/book.dart';
import 'package:urdu_book_studio/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('every language font is registered and used as the default', () {
    for (final language in kLanguages) {
      final font = fontForLanguage(language.code);
      if (font == null) continue;
      expect(kFonts, contains(font), reason: '${language.code} -> $font');
      expect(defaultStyleFor(language.code).fontFamily, font);
    }
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

  testWidgets('outline and AI tabs are reachable on narrow screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

    await tester.tap(find.text('Outline'));
    await tester.pumpAndSettle();
    expect(find.text('Heading outline'), findsOneWidget);

    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    expect(find.text('Translate text'), findsOneWidget);
    expect(find.text('API key'), findsWidgets);
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

  testWidgets('size slider changes the active block font size',
      (WidgetTester tester) async {
    final book = Book.create(title: 'Book', author: 'Author', languageCode: 'en');
    await tester.pumpWidget(MaterialApp(
      home: ChapterEditor(
        book: book,
        chapter: book.chapters.first,
        chapters: book.chapters,
        onChanged: () {},
      ),
    ));
    await tester.pumpAndSettle();

    final toolbar = find.byType(FontToolbar).first;
    final sizeSlider = find.descendant(
      of: toolbar,
      matching: find.byType(Slider),
    ).first;
    final slider = tester.widget<Slider>(sizeSlider);
    expect(slider.onChanged, isNotNull);
    slider.onChanged!(28);

    await tester.pumpAndSettle();
    expect(book.chapters.first.blocks.first.style.fontSize, 28);
    expect(find.text('Size 28'), findsWidgets);
  });

  testWidgets('font toolbar updates the block and Format tab reflects it',
      (WidgetTester tester) async {
    final book = Book.create(title: 'Book', author: 'Author', languageCode: 'en');
    await tester.pumpWidget(MaterialApp(
      home: ChapterEditor(
        book: book,
        chapter: book.chapters.first,
        chapters: book.chapters,
        onChanged: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('font_Roboto')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noto Naskh Arabic').last);
    await tester.pumpAndSettle();

    expect(
      book.chapters.first.blocks.first.style.fontFamily,
      'Noto Naskh Arabic',
    );

    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();
    final formatDropdown = find.descendant(
      of: find.byType(FontToolbar).last,
      matching: find.byType(DropdownButtonFormField<String>),
    );
    expect(
      tester.widget<DropdownButtonFormField<String>>(formatDropdown).initialValue,
      'Noto Naskh Arabic',
    );
  });

  testWidgets('selecting a template restyles every chapter',
      (WidgetTester tester) async {
    final book = Book.create(title: 'Book', author: 'Author', languageCode: 'en');
    final second = Chapter(title: 'Chapter 2', blocks: [Block(text: 'Second')]);
    book.chapters.add(second);
    await tester.pumpWidget(MaterialApp(
      home: ChapterEditor(
        book: book,
        chapter: book.chapters.first,
        chapters: book.chapters,
        onChanged: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('template_classic')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Naskh —').last);
    await tester.pumpAndSettle();

    for (final chapter in book.allChapters) {
      for (final block in chapter.blocks) {
        expect(block.style.fontFamily, 'Noto Naskh Arabic');
      }
    }
    expect(book.templateId, 'naskh');
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
