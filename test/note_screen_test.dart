import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });
  testWidgets('Render Note Screen', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.bySemanticsLabel('Title of the idea'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Note and links to other ideas'), findsOneWidget);
  });

  testWidgets('Backlinks are populated', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await createNoteWithBacklink(tester);
    expect(
        find.descendant(
          of: find.byType(NoteEditor),
          matching: find.text('[[link]]', findRichText: true),
        ),
        findsOneWidget);
  });

  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
    await tester.pump();

    expect(findSaveButton(tester).enabled, isTrue);
  });

  testWidgets('Save note button is disabled when pressed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
    await saveCurrentNote(tester);

    expect(findSaveButton(tester).enabled, isFalse);
  });

  testWidgets('Save note button shows snackbar if save failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();

    // test for snackbar failure
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
        supabase: mockSupabase);
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
    await saveCurrentNote(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Delete note shows snackbar if delete failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();
    // test for snackbar failure
    await fnPumpWidget(
      tester,
      const MaterialApp(home: MainScreen()),
      supabase: mockSupabase,
    );
    await deleteCurrentNote(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Changing titles updates backlinks', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await createNoteWithBacklink(tester);
    await tester.enterText(
        find.bySemanticsLabel('Title of the idea'), 'hello world');
    await saveCurrentNote(tester);
    await tester.pump(const Duration(seconds: 1)); // wait for notes to update
    expect(
        find.descendant(
          of: find.byType(NoteEditor),
          matching: find.text('[[hello world]]', findRichText: true),
        ),
        findsOneWidget);
  });
  testWidgets('Clicking TitleField removes LinkPreview overlay',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await clickLinkInContentField(tester);
    await tester.tap(find.byType(TitleField));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('Autosave works', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    // auto save
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'save');
    await tester.pump();
    expect(findSaveButton(tester).enabled, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(findSaveButton(tester).enabled, isFalse);

    // empty notes are not saved
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '');
    await tester.pump();
    expect(findSaveButton(tester).enabled, isFalse);
  });
  testWidgets('Cursor location doesnt change when handling note event',
      (WidgetTester tester) async {
    // setup
    var mocks =
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'save');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    var prevController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;

    // trigger handleNoteEvent
    var note = (await mocks.db.getAllNotes()).first;
    note.content = 'auto update note';
    mocks.db.noteChangeController
        .add(NoteEvent([note], NoteEventStatus.upsert));
    await tester.pump();

    var nextController =
        tester.widget<ContentField>(find.byType(ContentField)).controller;
    expect(prevController.selection == nextController.selection, isTrue);
  });
}

OutlinedButton findSaveButton(WidgetTester tester) {
  return tester.widget<OutlinedButton>(
    find.ancestor(
        of: find.text('Save'),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton)),
  );
}
