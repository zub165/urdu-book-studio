import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:urdu_book_studio/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('library screen starts empty', (WidgetTester tester) async {
    await tester.pumpWidget(const UrduBookStudioApp());
    await tester.pumpAndSettle();

    expect(
      find.text('No books yet. Tap "New book" or import a file.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsWidgets);
  });
}
