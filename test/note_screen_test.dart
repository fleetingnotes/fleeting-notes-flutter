import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });
  testWidgets('Render Note Screen', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    expect(find.bySemanticsLabel('New note title'), findsOneWidget);
    expect(find.bySemanticsLabel('Start writing your thoughts...'),
        findsOneWidget);
  });

  testWidgets('Changing titles updates backlinks', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());

    await addNote(tester, title: 'link', content: '[[link]]');
    await tester.enterText(
        find.bySemanticsLabel('New note title'), 'hello world');
    await saveCurrentNote(tester);
    await tester.pumpAndSettle(); // wait for notes to update
    expect(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.text('[[hello world]]', findRichText: true),
        ),
        findsOneWidget);
  });

  testWidgets('Clicking TitleField removes LinkPreview overlay',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await clickLinkInContentField(tester);
    await tester.tapAt(tester
        .getTopRight(find.bySemanticsLabel('Start writing your thoughts...'))
        .translate(-20, 10));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('Autosave works', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    // auto save
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save');
    await tester.pumpAndSettle();
    expect(findSaveButton(tester).onPressed, isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(findSaveButton(tester).onPressed, isNull);

    // empty notes are not saved
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), '');
    await tester.pump();
    expect(findSaveButton(tester).onPressed, isNull);
  });

  testWidgets('Cursor location doesnt change when handling note event',
      (WidgetTester tester) async {
    // setup
    var mocks = await fnPumpWidget(tester, const MyApp());
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    var prevController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;

    // trigger handleNoteEvent
    var note = (await mocks.db.getAllNotes()).first;
    note.modifiedAt =
        DateTime.now().add(const Duration(seconds: 5)).toIso8601String();
    note.content = 'auto update note';
    mocks.db.noteChangeController
        .add(NoteEvent([note], NoteEventStatus.upsert));
    await tester.pump();

    var nextController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;
    expect(prevController.selection == nextController.selection, isTrue);
  });

  testWidgets('Cursor location set to end of text if too short',
      (WidgetTester tester) async {
    // setup
    var mocks = await fnPumpWidget(tester, const MyApp());
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // trigger handleNoteEvent
    var note = (await mocks.db.getAllNotes()).first;
    note.modifiedAt =
        DateTime.now().add(const Duration(seconds: 5)).toIso8601String();
    note.content = 's';
    mocks.db.noteChangeController
        .add(NoteEvent([note], NoteEventStatus.upsert));
    await tester.pump();

    var nextController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;
    expect(nextController.selection.baseOffset == note.content.length, isTrue);
  });

  testWidgets(
      'NoteEvents that have a modified time within 5 seconds dont update fields',
      (WidgetTester tester) async {
    // setup
    var mocks = await fnPumpWidget(tester, const MyApp());
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // note updated within 5 seconds of previous note saved
    var note = (await mocks.db.getAllNotes()).first;
    note.content = 's';
    note.modifiedAt = DateTime.now().toUtc().toIso8601String();
    mocks.db.noteChangeController
        .add(NoteEvent([note], NoteEventStatus.upsert));
    await tester.pump();

    var nextController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;
    expect(nextController.text == 'save', isTrue);
  });

  testWidgets('Title field doesnt lose focus when typing',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.enterText(find.bySemanticsLabel('New note title'), 'test');
    await tester.pumpAndSettle();

    expect(contentFieldHasFocus(tester), isFalse);
  });

  testWidgets('New note has focus on content field',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(find.bySemanticsLabel('New note title'));
    await tester.pumpAndSettle();
    expect(contentFieldHasFocus(tester), isFalse);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(contentFieldHasFocus(tester), isTrue);
  });
}

bool? contentFieldHasFocus(WidgetTester tester) {
  return tester
      .widget<TextField>(find.ancestor(
          of: find.bySemanticsLabel('Start writing your thoughts...'),
          matching: find.byType(TextField)))
      .focusNode
      ?.hasFocus;
}
