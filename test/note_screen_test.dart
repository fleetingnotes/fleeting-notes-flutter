// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/screens/note/components/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen_navigator.dart';
import 'mock_database.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Render Note Screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    expect(find.bySemanticsLabel('Title of the idea'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Note and links to other ideas'), findsOneWidget);
  });

  testWidgets('Backlinks are populated', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any())).thenAnswer(
        (_) async => Future.value([Note.empty(content: 'backlink note')]));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.pumpAndSettle();

    expect(find.text('backlink note', findRichText: true), findsOneWidget);
  });

  testWidgets('Save note button is enabled when note is changed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.upsertNote(any()))
        .thenAnswer((_) async => Future.value(true));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
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
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.upsertNote(any()))
        .thenAnswer((_) async => Future.value(true));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
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

  testWidgets('Save note button shows snackbar if save failed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.upsertNote(any()))
        .thenAnswer((_) async => Future.value(false));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), 'new note');
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Delete note shows snackbar if delete failed',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.deleteNote(any()))
        .thenAnswer((_) async => Future.value(false));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Changing titles updates backlinks', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    mockDb.noteHistory = {Note.empty(title: 'hello'): GlobalKey()};
    when(() => mockDb.getBacklinkNotes(any())).thenAnswer(
        (_) async => Future.value([Note.empty(content: '[[hello]]')]));
    when(() => mockDb.upsertNote(any()))
        .thenAnswer((_) async => Future.value(true));
    when(() => mockDb.titleExists(any(), any()))
        .thenAnswer((_) async => Future.value(false));
    when(() => mockDb.updateNotes(any()))
        .thenAnswer((_) async => Future.value(true));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(
        find.bySemanticsLabel('Title of the idea'), 'hello world');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('[[hello world]]', findRichText: true), findsOneWidget);
  });

  testWidgets('Clicking TitleField removes LinkPreview overlay',
      (WidgetTester tester) async {
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any())).thenAnswer(
        (_) async => Future.value([Note.empty(content: '[[hello]]')]));
    when(() => mockDb.upsertNote(any()))
        .thenAnswer((_) async => Future.value(false));
    await tester.pumpWidget(MaterialApp(home: NoteScreenNavigator(db: mockDb)));
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'), '[[test]]');
    await tester.pump();
    await tester.tapAt(tester
        .getTopLeft(find.bySemanticsLabel('Note and links to other ideas'))
        .translate(20, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TitleField));
    await tester.pumpAndSettle();
    expect(find.byType(LinkPreview), findsNothing);
  });
}
