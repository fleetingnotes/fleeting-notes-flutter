import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

// Currently Only Testing Web
void main() {
  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'new note');
    await tester.pumpAndSettle();

    expect(findSaveButton(tester).onPressed, isNotNull);
  });

  testWidgets('Save note button is disabled when pressed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'new note');
    await saveCurrentNote(tester);

    expect(findSaveButton(tester).onPressed, isNull);
  });

  testWidgets('Save note button shows snackbar if save failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();

    // test for snackbar failure
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'new note');
    await saveCurrentNote(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Delete note shows snackbar if delete failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();
    // test for snackbar failure
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await deleteCurrentNote(tester);
    expect(find.byType(SnackBar), findsOneWidget);
  });
  testWidgets('Note history works', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'note 1');
    await addNote(tester, content: 'note 2');

    expect(findTextInContentField('note 2'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(NoteEditorAppBar),
        matching: find.byIcon(Icons.arrow_back)));
    await tester.pumpAndSettle();
    expect(findTextInContentField('note 1'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(NoteEditorAppBar),
        matching: find.byIcon(Icons.arrow_back)));
    await tester.pumpAndSettle();
    expect(findTextInContentField('note 1'), findsNothing);
    expect(findTextInContentField('note 2'), findsNothing);
  });

  testWidgets('Searching on mobile screen works preserves note history',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'note');

    expect(findTextInContentField('note'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(findTextInContentField('note'), findsOneWidget);
  });

  testWidgets('Searching on mobile screen works preserves note history',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'note');

    expect(findTextInContentField('note'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(findTextInContentField('note'), findsOneWidget);
  });

  testWidgets('Seeing backlinks updates search', (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    await modifyCurrentNote(tester, title: 'link');
    await tester.tap(find.descendant(
        of: find.byType(NoteCard),
        matching: find.text('link', findRichText: true)));
    await tester.pumpAndSettle();
    await seeCurrNoteBacklinks(tester);

    expect(
        find.descendant(
            of: findSearchbar(tester), matching: find.text('[[link]]')),
        findsOneWidget);
  });

  testWidgets('Clear note history goes back to search screen (mobile)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'testing');
    await clearNoteHistory(tester);

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });
}

Finder findTextInContentField(String text) {
  return find.descendant(
      of: find.byType(ContentField), matching: find.text(text));
}

IconButton findSaveButton(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.ancestor(
        of: find.byIcon(Icons.save),
        matching: find.byWidgetPredicate((widget) => widget is IconButton)),
  );
}
