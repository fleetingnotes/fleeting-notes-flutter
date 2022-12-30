import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
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
Future<void> addNote(WidgetTester tester,
    {String title = "", String content = "note"}) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await modifyCurrentNote(tester, title: title, content: content);
}

Future<void> modifyCurrentNote(WidgetTester tester,
    {String? title, String? content}) async {
  if (title != null) {
    await tester.enterText(find.bySemanticsLabel('Title of the idea'), title);
  }
  if (content != null) {
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), content);
  }
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle(
      const Duration(seconds: 1)); // Wait for animation to finish
}

Future<void> saveCurrentNote(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.byIcon(Icons.save));
  await tester.pump();
}

Future<void> deleteCurrentNote(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
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
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
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

Future<void> clickLinkInContentField(WidgetTester tester) async {
  await tester.enterText(find.bySemanticsLabel('Note and links to other ideas'),
      '[[hello world]]');
  await tester.pump();
  await tester.tapAt(tester
      .getTopLeft(find.bySemanticsLabel('Note and links to other ideas'))
      .translate(20, 10));
  await tester.pumpAndSettle();
}

Future<void> sortBy(WidgetTester tester, sortByText) async {
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  await tester
      .tap(find.widgetWithText(DropdownMenuItem<String>, sortByText).last);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
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
