import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'mocks/mock_database.dart';
import 'mocks/mock_local_file_sync.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';

class FNMocks {
  MockDatabase db;
  LocalFileSync localFs;
  SupabaseDB supabase;
  Settings settings;
  FNMocks(this.db, this.settings, this.supabase, this.localFs);
}

// init
Future<FNMocks> fnPumpWidget(
  WidgetTester tester,
  Widget widget, {
  bool isLoggedIn = false,
  Settings? settings,
  SupabaseDB? supabase,
  LocalFileSync? localFs,
  MockDatabase? db,
}) async {
  settings = settings ?? MockSettings();
  supabase = supabase ?? getBaseMockSupabaseDB();
  localFs =
      localFs ?? LocalFileSync(settings: settings, fs: MemoryFileSystem());
  MockDatabase mockDb = db ??
      MockDatabase(
        settings: settings,
        supabase: supabase,
        localFileSync: localFs,
      );

  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(mockDb),
      settingsProvider.overrideWithValue(settings),
      supabaseProvider.overrideWithValue(supabase),
      localFileSyncProvider.overrideWithValue(localFs),
    ],
    child: widget,
  ));
  await tester.pumpAndSettle();
  return FNMocks(mockDb, settings, supabase, localFs);
}

// resizing
Future<void> resizeToDesktop(WidgetTester tester) async {
  tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
}

Future<void> resizeToMobile(WidgetTester tester) async {
  tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  tester.binding.window.devicePixelRatioTestValue = 1.0;
}

// screen interactions
Future<void> searchNotes(WidgetTester tester, String query) async {
  await tester.enterText(
      find.descendant(
          of: find.byType(SearchScreen), matching: find.byType(TextField)),
      query);
}

Future<void> goToNewNote(WidgetTester tester,
    {String title = '',
    String content = '',
    String source = '',
    bool addQueryParams = false}) async {
  final BuildContext context = tester.element(find.byType(MainScreen));
  final newNote = Note.empty(title: title, content: content, source: source);
  Map<String, String> qp = (addQueryParams)
      ? {'title': title, 'content': content, 'source': source}
      : {};
  context.goNamed('note',
      params: {'id': newNote.id}, extra: newNote, queryParams: qp);
  await tester.pumpAndSettle();
}

Future<void> addNote(WidgetTester tester,
    {String title = "",
    String content = "note",
    String source = "",
    bool closeDialog = false}) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await modifyCurrentNote(tester,
      title: title, content: content, source: source, closeDialog: closeDialog);
}

Future<void> modifyCurrentNote(
  WidgetTester tester, {
  String? title,
  String? content,
  String? source,
  bool closeDialog = false,
}) async {
  if (title != null) {
    await tester.enterText(find.bySemanticsLabel('Title'), title);
  }
  if (content != null) {
    await tester.enterText(
        find.bySemanticsLabel('Start writing your thoughts...'), content);
  }
  if (source != null) {
    await tester.enterText(find.bySemanticsLabel('Source'), source);
  }
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.save));
  await tester.pumpAndSettle(
      const Duration(seconds: 1)); // Wait for animation to finish
  if (closeDialog) {
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  }
}

Future<void> saveCurrentNote(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.byIcon(Icons.save));
  await tester.pump();
}

Future<void> deleteCurrentNote(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
}

Future<void> seeCurrNoteBacklinks(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.link));
  await tester.pumpAndSettle();
}

Future<void> clearNoteHistory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.close));
  await tester.pumpAndSettle();
}

Finder findSearchbar(WidgetTester tester) {
  return find.descendant(
      of: find.byType(SearchScreen), matching: find.byType(TextField));
}

IconButton findIconButtonByIcon(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(
    find.ancestor(
        of: find.byIcon(icon),
        matching: find.byWidgetPredicate((widget) => widget is IconButton)),
  );
}

Future<void> createNoteWithBacklink(WidgetTester tester) async {
  await addNote(tester, title: 'link');
  await addNote(tester, content: '[[link]]');
  await tester.tap(find.descendant(
    of: find.byType(NoteCard),
    matching: find.text('link', findRichText: true),
  ));
  await tester.pumpAndSettle();
}

Future<void> navigateToSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

Future<void> attemptLogin(WidgetTester tester) async {
  final richText = find.byKey(const Key('SignInText')).first;
  fireOnTap(richText, 'Sign in');
  await tester.pumpAndSettle();
  await tester.enterText(find.bySemanticsLabel("Enter your email"), 'matt@g.g');
  await tester.enterText(find.bySemanticsLabel("Password"), '222222');
  await tester.tap(find.text('Sign in'));
  await tester.pump(); // pumpAndSettle doesnt work with circular progress
}

Future<void> clickLinkInContentField(WidgetTester tester,
    {String linkName = "hello world"}) async {
  await tester.enterText(
      find.bySemanticsLabel('Start writing your thoughts...'), '[[$linkName]]');
  await tester.pump();
  await tester.tap(find.byIcon(Icons.save));
  await tester.pumpAndSettle();
  await tester.tapAt(tester
      .getTopLeft(find.bySemanticsLabel('Start writing your thoughts...'))
      .translate(20, 10));
  await tester.pumpAndSettle();
}

Future<void> sortBy(WidgetTester tester, String sortByText,
    {bool asc = true}) async {
  await tester.tap(find.descendant(
      of: find.byType(SearchScreen), matching: find.byType(TextField)));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.tune));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownSortMenu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sortByText, findRichText: true).last);

  await tester.pumpAndSettle();
  if (asc) {
    await tester.tap(find.byIcon(Icons.arrow_downward));
  }
  await tester.pumpAndSettle();
}

List<String> getContentNoteCardList(WidgetTester tester) {
  return tester
      .widgetList<NoteCard>(find.byType(NoteCard))
      .map((nc) => nc.note.content)
      .toList();
}

// get mock object
MockSupabaseDB getSupabaseMockThrowOnUpsert() {
  var mockSupabase = getBaseMockSupabaseDB();
  mockSupabase.currUser = getUser();
  when(() => mockSupabase.upsertNotes(any()))
      .thenThrow(FleetingNotesException('Failed'));
  return mockSupabase;
}

/// Runs the onTap handler for the [TextSpan] which matches the search-string.
/// https://github.com/flutter/flutter/issues/56023#issuecomment-764985456
void fireOnTap(Finder finder, String text) {
  final Element element = finder.evaluate().single;
  final RenderParagraph paragraph = element.renderObject as RenderParagraph;
  // The children are the individual TextSpans which have GestureRecognizers
  paragraph.text.visitChildren((dynamic span) {
    if (span.text != text) return true; // continue iterating.

    (span.recognizer as TapGestureRecognizer).onTap!();
    return false; // stop iterating, we found the one.
  });
}

Future<MockLocalFileSync> setupLfs({
  bool enabled = true,
  MockSettings? settings,
  FileSystem? fs,
}) async {
  fs = fs ?? MemoryFileSystem();
  var f = fs.systemTempDirectory.createTempSync();
  settings = settings ?? MockSettings();
  settings.set('local-sync-enabled', enabled);
  settings.set('local-sync-dir', f.path);
  var lfs = MockLocalFileSync(settings: settings, fs: fs);
  return lfs;
}
