import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mocks/mock_database.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';

// init
Future<void> fnPumpWidget(
  WidgetTester tester,
  Widget widget, {
  bool isLoggedIn = false,
  MockSettings? settings,
  MockSupabaseDB? supabase,
}) async {
  settings = settings ?? MockSettings();
  supabase = supabase ?? MockSupabaseDB();
  MockDatabase mockDb = MockDatabase(settings: settings, supabase: supabase);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(mockDb),
      settingsProvider.overrideWithValue(MockSettings()),
      supabaseProvider.overrideWithValue(MockSupabaseDB())
    ],
    child: widget,
  ));
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
  await tester.enterText(find.bySemanticsLabel('Title of the idea'), title);
  await tester.enterText(
      find.bySemanticsLabel('Note and links to other ideas'), content);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle(); // Wait for animation to finish
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
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

Future<void> clickLinkInContentField(WidgetTester tester) async {
  await tester.enterText(find.bySemanticsLabel('Note and links to other ideas'),
      '[[hello world]]');
  await tester.pump();
  await tester.tapAt(tester
      .getTopLeft(find.bySemanticsLabel('Note and links to other ideas'))
      .translate(20, 10));
  await tester.pumpAndSettle();
}

// get mock object
MockSupabaseDB getSupabaseMockLoggedIn() {
  var mockSupabase = MockSupabaseDB();
  when(() => mockSupabase.currUser).thenReturn(const User(
      id: '', appMetadata: {}, userMetadata: {}, aud: '', createdAt: ''));
  return mockSupabase;
}

MockSupabaseDB getSupabaseMockThrowOnUpsert() {
  var mockSupabase = getSupabaseMockLoggedIn();
  when(() => mockSupabase.upsertNotes(any()))
      .thenThrow(FleetingNotesException('Failed'));
  return mockSupabase;
}
