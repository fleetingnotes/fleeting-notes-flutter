// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/screens/note/components/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/link_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mock_database.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('LinkPreview appears on link tap', (WidgetTester tester) async {
    MockDatabase mockDb = MockDatabase();
    TextEditingController controller = TextEditingController();
    when(() => mockDb.getAllLinks())
        .thenAnswer((_) async => Future.value(['hello', 'world']));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ContentField(
        db: mockDb,
        controller: controller,
        onChanged: () {},
      ),
    )));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '[[test]]');
    await tester.pump();
    await tester.tapAt(tester
        .getTopLeft(find.bySemanticsLabel('Note and links to other ideas'))
        .translate(20, 10));
    await tester.pumpAndSettle();

    expect(find.byType(LinkPreview), findsOneWidget);
  });

  testWidgets('TitleLinks list appears on `[[` type',
      (WidgetTester tester) async {
    MockDatabase mockDb = MockDatabase();
    TextEditingController controller = TextEditingController();
    when(() => mockDb.getAllLinks())
        .thenAnswer((_) async => Future.value(['hello']));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ContentField(
        db: mockDb,
        controller: controller,
        onChanged: () {},
      ),
    )));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '[[');
    await tester.pump();

    expect(find.byType(LinkSuggestions), findsOneWidget);
  });

  testWidgets('Key navigation works in TitleLinks',
      (WidgetTester tester) async {
    MockDatabase mockDb = MockDatabase();
    TextEditingController controller = TextEditingController();
    when(() => mockDb.getAllLinks())
        .thenAnswer((_) async => Future.value(['hello', 'world']));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ContentField(
        db: mockDb,
        controller: controller,
        onChanged: () {},
      ),
    )));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '[[');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.byType(LinkSuggestions), findsNothing);
    expect(find.text('[[world]]'), findsOneWidget);
  });

  testWidgets('Key navigation doesnt break on left key navigation',
      (WidgetTester tester) async {
    MockDatabase mockDb = MockDatabase();
    TextEditingController controller = TextEditingController();
    when(() => mockDb.getAllLinks())
        .thenAnswer((_) async => Future.value(['hello', 'world']));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ContentField(
        db: mockDb,
        controller: controller,
        onChanged: () {},
      ),
    )));
    await tester.tap(find.bySemanticsLabel('Note and links to other ideas'));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '[[');
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(find.byType(LinkSuggestions), findsNothing);
  });
}
