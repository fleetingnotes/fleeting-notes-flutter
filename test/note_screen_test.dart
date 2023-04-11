import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
    registerFallbackValue(SearchQuery());
  });
  testWidgets('Render Note Screen', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(NoteEditorAppBar), findsOneWidget);
    expect(find.byType(NoteEditorBottomAppBar), findsNothing);
  });

  testWidgets('Changing titles updates backlinks', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, title: 'link', content: '[[link]]');
    await tester.enterText(find.bySemanticsLabel('Title'), 'hello world');
    await saveCurrentNote(tester);
    await tester.pumpAndSettle(); // wait for notes to update
    expect(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.text('[[hello world]]', findRichText: true),
        ),
        findsOneWidget);
  });

  testWidgets('Clicking outside of ContentField removes LinkPreview overlay',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await clickLinkInContentField(tester);
    await tester.tapAt(tester
        .getTopRight(find.bySemanticsLabel('Start writing your thoughts...'))
        .translate(-20, 10));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('Note is not auto saved if new', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    // auto save
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save');
    await tester.pumpAndSettle();
    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
  });

  testWidgets('Note is autosaved if exists in db', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'save');
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), 'save asdf');
    // auto save
    await tester.pumpAndSettle();
    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNull);
  });

  testWidgets('Cursor location doesnt change when handling note event',
      (WidgetTester tester) async {
    // setup
    var mocks = await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await modifyCurrentNote(tester, content: 'save');
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
    await goToNewNote(tester);
    await modifyCurrentNote(tester, content: 'save');

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
    await goToNewNote(tester);
    await modifyCurrentNote(tester, content: 'save');

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
    await goToNewNote(tester);
    await tester.enterText(find.bySemanticsLabel('Title'), 'test');
    await tester.pumpAndSettle();

    expect(contentFieldHasFocus(tester), isFalse);
  });

  testWidgets('New note has focus on content field',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await tester.pumpAndSettle();
    expect(contentFieldHasFocus(tester), isTrue);
  });

  testWidgets('New note with source preview has focus on content field',
      (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getUrlMetadata(any())).thenAnswer((_) =>
        Future.value(UrlMetadata(
            url: 'https://test.test',
            title: 'Test',
            description: 'Test',
            imageUrl: 'https://test.image/')));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await goToNewNote(tester, source: 'https://test.test');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(contentFieldHasFocus(tester), isTrue);
  });

  testWidgets('auth change refreshes current note',
      (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await modifyCurrentNote(tester, content: 'init note');
    mocks.supabase.authChangeController.add(AuthChangeEvent.signedIn);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(ContentField), matching: find.text('init note')),
        findsNothing);
  });

  group("Sharing note with same source", () {
    testWidgets('Opens prev note', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world', source: 'source', closeDialog: true);
      await goToNewNote(tester,
          source: 'source', content: '', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(
          find.descendant(
              of: find.bySemanticsLabel('Start writing your thoughts...'),
              matching: find.text('hello world', findRichText: true)),
          findsOneWidget);
    });
    testWidgets('Appends content with same source',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world', source: 'source', closeDialog: true);
      await goToNewNote(tester,
          source: 'source', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(
          find.descendant(
              of: find.bySemanticsLabel('Start writing your thoughts...'),
              matching: find.text('hello world\npp', findRichText: true)),
          findsOneWidget);
    });
    testWidgets('Appends content with other note open',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world', source: 'source', closeDialog: true);
      await addNote(tester,
          content: 'open note', source: 'smthin else', closeDialog: false);
      await goToNewNote(tester,
          source: 'source', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(
          find.descendant(
              of: find.bySemanticsLabel('Start writing your thoughts...'),
              matching: find.text('hello world\npp', findRichText: true)),
          findsOneWidget);
    });
    testWidgets('Appends content with same note open',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world', source: 'source', closeDialog: false);
      await goToNewNote(tester,
          source: 'source', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(findIconButtonByIcon(tester, Icons.save).onPressed, isNotNull);
      expect(
          find.descendant(
              of: find.bySemanticsLabel('Start writing your thoughts...'),
              matching: find.text('hello world\npp', findRichText: true)),
          findsOneWidget);
    });
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
