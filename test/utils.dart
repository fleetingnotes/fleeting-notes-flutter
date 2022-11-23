import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mocks/mock_database.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';

Future<void> fnPumpWidget(WidgetTester tester, Widget widget) async {
  MockSettings mockSettings = MockSettings();
  MockSupabaseDB mockSupabase = MockSupabaseDB();
  MockDatabase mockDb =
      MockDatabase(settings: mockSettings, supabase: mockSupabase);
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

Future<void> addNote(WidgetTester tester, {String content = "Note"}) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.bySemanticsLabel('Note and links to other ideas'), content);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle(); // Wait for animation to finish
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
}

Future<void> deleteCurrentNote(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1)); // wait for notes to update
}
