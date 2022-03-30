// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mock_realm_db.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Render settings when logged in', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.isLoggedIn()).thenAnswer((_) => true);
    when(() => mockDb.getEmail()).thenAnswer((_) => Future.value('test'));
    await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(
      db: mockDb,
      onAuthChange: () {},
    )));
    // await tester.pumpAndSettle();
    expect(find.byType(Auth), findsNothing);
  });

  testWidgets('Render settings when not logged in',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
    when(() => mockDb.getEmail()).thenAnswer((_) => Future.value('test'));
    await tester.pumpWidget(MaterialApp(
        home: SettingsScreen(
      db: mockDb,
      onAuthChange: () {},
    )));
    expect(find.byType(Auth), findsOneWidget);
  });
}
