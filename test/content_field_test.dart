// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('LinkPreview appears on link tap', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await clickLinkInContentField(tester);
    expect(find.byType(LinkPreview), findsOneWidget);
  });

  // TODO: make this test pass
  testWidgets('LinkPreview disappears when pressing title field',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await clickLinkInContentField(tester);
    await tester.tap(find.bySemanticsLabel('Title'));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  }, skip: true);

  testWidgets('Suggestions list appears on `[[` type',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), '[[');
    await tester.pump();
    expect(find.byType(Suggestions), findsOneWidget);
  });

  testWidgets('Suggestions list appears on `#` type',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), '#');
    await tester.pump();
    expect(find.byType(Suggestions), findsOneWidget);
  });

  testWidgets('Key navigation works in Suggestions',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await setupSuggestions(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(Suggestions), findsNothing);
    expect(
        find.descendant(
            of: find.byType(ContentField), matching: find.text('[[world]]')),
        findsOneWidget);
  });

  testWidgets('Key navigation doesnt break on left key navigation',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await setupSuggestions(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(find.byType(Suggestions), findsNothing);
  });

  group('List syntax tests', () {
    testWidgets('empty bullet list removes itself on enter',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '- \n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField), matching: find.text('- \n')),
          findsNothing);
    });
    testWidgets('nested bullet points popualte on enter',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '  - test\n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField),
              matching: find.text('  - test\n  - ')),
          findsOneWidget);
    });
    testWidgets('bullet list populate on enter', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '- test\n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField), matching: find.text('- test\n- ')),
          findsOneWidget);
    });
    testWidgets('checkbox populate on enter', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '- [ ] test\n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField),
              matching: find.text('- [ ] test\n- [ ] ')),
          findsOneWidget);
    });
    testWidgets('numbered list populate on enter', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '1. test\n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField),
              matching: find.text('1. test\n2. ')),
          findsOneWidget);
    });
    testWidgets('nested numbered list', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: '  1. test\n', closeDialog: false);
      expect(
          find.descendant(
              of: find.byType(ContentField),
              matching: find.text('  1. test\n  2. ')),
          findsOneWidget);
    });
  });
  testWidgets('setting content controller text enables save button',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    var contentController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;
    contentController.text = 'set text';

    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNull);
    await tester.pump();
    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
  });
}

Future<void> setupSuggestions(WidgetTester tester) async {
  // add notes
  await addNote(tester, title: 'hello', closeDialog: true);
  await addNote(tester, content: '[[world]]', closeDialog: true);
  await addNote(tester);

  // trigger link suggestion
  await tester.tap(find.bySemanticsLabel('Start writing your thoughts...'));
  await tester.enterText(
      find.bySemanticsLabel('Start writing your thoughts...'), '[[');
  await tester.pump();
}
