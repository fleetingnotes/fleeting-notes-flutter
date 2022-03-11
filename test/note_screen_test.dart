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
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    expect(find.bySemanticsLabel('Title'), findsOneWidget);
    expect(find.bySemanticsLabel('Note'), findsOneWidget);
  });

  testWidgets('Follow link button appears on link tap',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(find.bySemanticsLabel('Note'), '[[test]]');
    await tester.pump();
    await tester.tapAt(
        tester.getTopLeft(find.bySemanticsLabel('Note')).translate(20, 10));
    await tester.pump();

    expect(find.text('Follow Link'), findsOneWidget);
  });

  testWidgets('TitleLinks list appears on `[[` type',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getAllLinks())
        .thenAnswer((_) async => Future.value(['hello']));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(find.bySemanticsLabel('Note'), '[[');
    await tester.pump();

    expect(find.byType(TitleLinks), findsOneWidget);
  });

  testWidgets('Backlinks are populated', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any())).thenAnswer(
        (_) async => Future.value([Note.empty(content: 'backlink note')]));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.pumpAndSettle();

    expect(find.text('backlink note'), findsOneWidget);
  });

  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
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
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
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

  testWidgets('Empty source field shows Add Source Url',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreen(db: mockDb, note: Note.empty())));

    expect(find.text('Add Source URL'), findsOneWidget);
    expect(find.bySemanticsLabel('Source'), findsNothing);
  });

  testWidgets('Filled source shows Source field', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    Note note = Note.empty();
    note.source = 'filled source';
    await tester
        .pumpWidget(MaterialApp(home: NoteScreen(db: mockDb, note: note)));

    expect(find.text('Add Source URL'), findsNothing);
    expect(find.bySemanticsLabel('Source'), findsOneWidget);
  });

  testWidgets('Clicking Add Source URL button shows source field',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(
        MaterialApp(home: NoteScreen(db: mockDb, note: Note.empty())));

    await tester.tap(find.text('Add Source URL'));
    await tester.pump();

    expect(find.text('Add Source URL'), findsNothing);
    expect(find.bySemanticsLabel('Source'), findsOneWidget);
  });
}
