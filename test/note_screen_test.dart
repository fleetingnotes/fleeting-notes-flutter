// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/screens/note/components/title_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'mock_realm_db.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Render Note Screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreenNavigator(db: mockDb, note: Note.empty())));
    expect(find.bySemanticsLabel('Title'), findsOneWidget);
    expect(find.bySemanticsLabel('Note'), findsOneWidget);
  });

  testWidgets('Backlinks are populated', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any())).thenAnswer(
        (_) async => Future.value([Note.empty(content: 'backlink note')]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreenNavigator(db: mockDb, note: Note.empty())));
    await tester.pumpAndSettle();

    expect(find.text('backlink note'), findsOneWidget);
  });

  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreenNavigator(db: mockDb, note: Note.empty())));
    await tester.enterText(find.bySemanticsLabel('Note'), 'new note');
    await tester.pump();

    expect(
        tester
            .widget<ElevatedButton>(
              find.ancestor(
                  of: find.text('Save'),
                  matching: find
                      .byWidgetPredicate((widget) => widget is ElevatedButton)),
            )
            .enabled,
        isTrue);
  });

  testWidgets('Save note button is disabled when pressed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreenNavigator(db: mockDb, note: Note.empty())));
    await tester.enterText(find.bySemanticsLabel('Note'), 'new note');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(
        tester
            .widget<ElevatedButton>(
              find.ancestor(
                  of: find.text('Save'),
                  matching: find
                      .byWidgetPredicate((widget) => widget is ElevatedButton)),
            )
            .enabled,
        isFalse);
  });
}
