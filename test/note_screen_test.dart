import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
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

    expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                  of: find.text('Save'),
                  matching: find
                      .byWidgetPredicate((widget) => widget is OutlinedButton)),
            )
            .enabled,
        isTrue);
  });

  testWidgets('Save note button is disabled when pressed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
    await saveCurrentNote(tester);

    expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                  of: find.text('Save'),
                  matching: find
                      .byWidgetPredicate((widget) => widget is OutlinedButton)),
            )
            .enabled,
        isFalse);
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
}
