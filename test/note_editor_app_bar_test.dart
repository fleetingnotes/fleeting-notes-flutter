import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/backlinks_drawer.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

void main() {
  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'new note');
    await tester.pump();

    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
  });

  testWidgets('Save note button is disabled when pressed',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'new note');

    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNull);
  });

  testWidgets('Save note button shows snackbar if save failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();

    // test for snackbar failure
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await addNote(tester, content: 'new note');
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Delete note shows snackbar if delete failed',
      (WidgetTester tester) async {
    // mock supabase to fail on upsert
    var mockSupabase = getSupabaseMockThrowOnUpsert();
    // test for snackbar failure
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await addNote(tester);
    await deleteCurrentNote(tester);
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  // Note traversal tests
  testWidgets('New note has no history', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);

    expect(findIconButtonByIcon(tester, Icons.arrow_back).onPressed, isNull);
    expect(findIconButtonByIcon(tester, Icons.arrow_forward).onPressed, isNull);
  });

  testWidgets('Traversing forwards by clicking link preview',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await clickLinkInContentField(tester, linkName: 'link');
    await tester.tap(find.descendant(
        of: find.byType(LinkPreview), matching: find.byType(NoteCard)));
    await tester.pumpAndSettle();

    expect(findIconButtonByIcon(tester, Icons.arrow_back).onPressed, isNotNull);
    expect(findIconButtonByIcon(tester, Icons.arrow_forward).onPressed, isNull);
    expect(find.text('Backlinks', findRichText: true), findsOneWidget);
    expect(
        find.descendant(
            of: find.bySemanticsLabel('Title'), matching: find.text('link')),
        findsOneWidget);
  });

  testWidgets('Traversing forwards and back', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await clickLinkInContentField(tester, linkName: 'link');
    await tester.tap(find.descendant(
        of: find.byType(LinkPreview), matching: find.byType(NoteCard)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(findIconButtonByIcon(tester, Icons.arrow_back).onPressed, isNull);
    expect(
        findIconButtonByIcon(tester, Icons.arrow_forward).onPressed, isNotNull);
    expect(find.text('Backlinks', findRichText: true), findsNothing);
    expect(
        find.descendant(
            of: find.bySemanticsLabel('Title'), matching: find.text('link')),
        findsNothing);
  });
  testWidgets('No backlinks button when no backlinks exist',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    expect(find.text('Backlinks', findRichText: true), findsNothing);
  });

  testWidgets('See backlinks button when backlinks exist',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: '[[link]]', closeDialog: true);
    await addNote(tester, title: 'link', closeDialog: true);
    await tester.tap(find.text('link', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Backlinks', findRichText: true), findsOneWidget);
  });

  testWidgets('Clicking backlinks button opens drawer with backlinks',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: '[[link]]', closeDialog: true);
    await addNote(tester, title: 'link', closeDialog: true);
    await tester.tap(find.text('link', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backlinks', findRichText: true));
    await tester.pumpAndSettle();

    expect(
        find.descendant(
            of: find.byType(BacklinksDrawer),
            matching: find.text('[[link]]', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Closing app bar goes back to notescreen',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'testing');
    expect(find.byType(NoteEditor), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });
}

Finder findTextInContentField(String text) {
  return find.descendant(
      of: find.byType(ContentField), matching: find.text(text));
}
