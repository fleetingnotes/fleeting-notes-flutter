// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

class MockRealmDB extends Mock implements RealmDB {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });
  testWidgets('Render Main Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    MockRealmDB mockDb = MockRealmDB();
    // await when(mockDb).calls("getSearchNotes")
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));

    // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();
  });
}
