import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
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

// TODO Fix and figure out why its bugged ;-;
  testWidgets('Changing titles updates backlinks', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, title: 'hey', content: '[[link]]', closeDialog: true);
    await addNote(tester, title: 'link', closeDialog: true);
    await tester.tap(find.text('link', findRichText: true));
    await tester.pumpAndSettle();
    await modifyCurrentNote(tester, title: 'hello world', closeDialog: true);
    await tester.tap(find.text('link', findRichText: true));

    print(getContentFieldText(tester));
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
        .getTopRight(find.descendant(
            of: find.byType(ContentField), matching: find.byType(TextField)))
        .translate(-20, 10));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('Note is not auto saved if new', (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    // auto save
    await tester.enterText(
        find.descendant(
            of: find.byType(ContentField), matching: find.byType(TextField)),
        'save');
    await tester.pumpAndSettle();
    expect(mocks.settings.get('unsaved-note'), isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(mocks.settings.get('unsaved-note'), isNotNull);
  });

  testWidgets('Note is autosaved if exists in db', (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    await createSavedNote(tester, 'save');
    await tester.enterText(
        find.descendant(
            of: find.byType(ContentField), matching: find.byType(TextField)),
        'save asdf');
    // auto save
    await tester.pumpAndSettle();
    expect(mocks.settings.get('unsaved-note'), isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(mocks.settings.get('unsaved-note'), isNull);
  });

  testWidgets('Cursor location doesnt change when handling note event',
      (WidgetTester tester) async {
    // setup
    var mocks = await fnPumpWidget(tester, const MyApp());
    await createSavedNote(tester, 'save');
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
    await createSavedNote(tester, 'save');
    await tester.tap(find.byType(ContentField));

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
    await createSavedNote(tester, 'save');

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

  testWidgets('New note has focus on text field by default',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await tester.pumpAndSettle();

    expect(titleFieldHasFocus(tester), isTrue);
  });

  testWidgets('New note has focus on content field if is enabled by settings',
      (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    await mocks.db.settings.set('auto-focus-title', false);
    await goToNewNote(tester);
    await tester.pumpAndSettle();
    expect(contentFieldHasFocus(tester), isTrue);
  });

  testWidgets('Existing note has no focus if content is filled',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester, content: 'init note');
    await tester.pumpAndSettle();

    expect(titleFieldHasFocus(tester), isFalse);
    expect(contentFieldHasFocus(tester), isFalse);
  });

  testWidgets('Existing note has no focus if title is filled',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester, title: 'init note');
    await tester.pumpAndSettle();

    expect(titleFieldHasFocus(tester), isFalse);
    expect(contentFieldHasFocus(tester), isFalse);
  });

  testWidgets('Changing orientation maintains unsaved note',
      (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    var testId = '00000000-0000-0000-0000-000000000000';

    // Setting unsaved note
    await mocks.db.settings
        .set('unsaved-note', Note.empty(id: testId, content: 'content'));

    // "Change orientations" by going to new note
    await goToNewNote(tester, id: testId);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('New note with same source as unsaved note opens unsaved',
      (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());

    // Setting unsaved note
    await mocks.db.settings
        .set('unsaved-note', Note.empty(content: 'content', source: 'source'));

    // "Change orientations" by going to new note
    await goToNewNote(tester, source: 'source');
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('New note with source preview has focus on title field',
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

    expect(titleFieldHasFocus(tester), isTrue);
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
// issue is that source as is, is dependent on clicking into the source field to
//input sources, now I gott make sure that the source is inserted into the
// content field and then searched and found without deleting the existing
// content and the source is added in the beginning. I will need to make sure that
// the sources are URLS that can be functionally used.
// I have to make sure that the content field will function additively
// If the link is in the content dont add it into the content again, if it is not add
// make function addSourceToContent
//
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world',
          source: 'https://test.test',
          closeDialog: true);
      await goToNewNote(tester,
          source: 'https://test.test', content: '', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(getContentFieldText(tester) == 'https://test.test\nhello world',
          isTrue);
    });
    testWidgets('Appends content with same source',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world',
          source: 'https://test.test',
          closeDialog: true);
      await goToNewNote(tester,
          source: 'https://test.test', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(
          getContentFieldText(tester) == 'https://test.test\nhello world\npp',
          isTrue);
    });
    testWidgets('Appends content with other note open',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world',
          source: 'https://test.test',
          closeDialog: true);
      await addNote(tester,
          content: 'open note',
          source: 'https://test2.test',
          closeDialog: false);
      await goToNewNote(tester,
          source: 'https://test.test', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(
          getContentFieldText(tester) == 'https://test.test\nhello world\npp',
          isTrue);
    });
    testWidgets('Appends content with same note open',
        (WidgetTester tester) async {
      var mocks = await fnPumpWidget(tester, const MyApp());
      await addNote(tester,
          content: 'hello world',
          source: 'https://test.test',
          closeDialog: false);
      await goToNewNote(tester,
          source: 'https://test.test', content: 'pp', addQueryParams: true);
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(mocks.settings.get('unsaved-note'), isNotNull);
      expect(
          getContentFieldText(tester) == 'https://test.test\nhello world\npp',
          isTrue);
    });
  });

  testWidgets('Sharing note w/ diff source saves overwritten note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'hello world', closeDialog: false);
    await goToNewNote(tester, content: 'pp', addQueryParams: true);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.text('hello world', findRichText: true),
        ),
        findsOneWidget);
  });

  testWidgets('Sharing new note w/ note open, opens new note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'hello world', closeDialog: false);
    await goToNewNote(tester, addQueryParams: true);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
          of: find.byType(NoteEditor),
          matching: find.text('hello world', findRichText: true),
        ),
        findsNothing);
  });

  testWidgets('New note has text direction ltr by default',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<TitleField>(find.byType(TitleField)).textDirection,
        TextDirection.ltr);
    expect(
        tester
            .widget<SourceContainer>(find.byType(SourceContainer))
            .textDirection,
        TextDirection.ltr);
    expect(tester.widget<ContentField>(find.byType(ContentField)).textDirection,
        TextDirection.ltr);
  });

  testWidgets('New note has text direction rtl if is enabled by settings',
      (WidgetTester tester) async {
    var mocks = await fnPumpWidget(tester, const MyApp());
    await mocks.db.settings.set('right-to-left', true);
    await goToNewNote(tester);
    await tester.pumpAndSettle();

    expect(tester.widget<TitleField>(find.byType(TitleField)).textDirection,
        TextDirection.rtl);
    expect(
        tester
            .widget<SourceContainer>(find.byType(SourceContainer))
            .textDirection,
        TextDirection.rtl);
    expect(tester.widget<ContentField>(find.byType(ContentField)).textDirection,
        TextDirection.rtl);
  });
}

bool? titleFieldHasFocus(WidgetTester tester) {
  return tester.widget<TitleField>(find.byType(TitleField)).autofocus;
}

bool? contentFieldHasFocus(WidgetTester tester) {
  return tester.widget<ContentField>(find.byType(ContentField)).autofocus;
}

String? getContentFieldText(WidgetTester tester) {
  return tester.widget<ContentField>(find.byType(ContentField)).controller.text;
}

Future<void> createSavedNote(WidgetTester tester, String text) async {
  await addNote(tester, content: text, closeDialog: true);
  await tester.tap(find.text(text, findRichText: true));
  await tester.pumpAndSettle();
}
