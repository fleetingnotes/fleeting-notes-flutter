import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
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
    {String title = "", String content = "Note"}) async {
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

// get mock object
MockSupabaseDB getSupabaseMockThrowOnUpsert() {
  var mockSupabase = MockSupabaseDB();
  when(() => mockSupabase.currUser).thenReturn(const User(
      id: '', appMetadata: {}, userMetadata: {}, aud: '', createdAt: ''));
  when(() => mockSupabase.upsertNotes(any()))
      .thenThrow(FleetingNotesException('Failed'));
  return mockSupabase;
}
