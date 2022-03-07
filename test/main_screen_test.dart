// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
@TestOn('browser')
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/screens/auth/auth_screen.dart';
import 'package:fleeting_notes_flutter/components/note_card.dart';
import 'mock_realm_db.dart';

// Currently Only Testing Web
void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Render Main Screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    expect(find.byType(NoteScreen), findsOneWidget);
    expect(find.byType(ListOfNotes), findsOneWidget);
  });

  testWidgets('Press new note button adds new note',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.byType(NoteScreen), findsNWidgets(2));
    expect(find.byType(ListOfNotes), findsOneWidget);
  });

  testWidgets('Clicking NoteCard populates NoteScreen and sets active note',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    Note newNote = Note.empty(content: 'Click me note!');
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([newNote]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.pump();
    await tester.tap(find.widgetWithText(NoteCard, 'Click me note!'));
    await tester.pumpAndSettle(); // Wait for animation to finish
    expect(find.widgetWithText(NoteScreen, 'Click me note!'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.descendant(
              of: find.byType(ListOfNotes),
              matching: find.text('Click me note!'),
            ))
            .style!
            .color,
        Colors.white);
  });

  testWidgets('Save note updates list of notes', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.titleExists(any(), any()))
        .thenAnswer((_) async => Future.value(false));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.enterText(find.bySemanticsLabel('Title'), 'Test save note!');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.widgetWithText(ListOfNotes, 'Test save note!'), findsOneWidget);
    expect(find.byType(NoteScreen), findsOneWidget);
  });

  testWidgets('Delete note updates list of notes', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    Note newNote = Note.empty(content: 'Test delete note!');
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([newNote]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.pump();
    await tester.tap(find.widgetWithText(NoteCard, 'Test delete note!'));
    await tester.pumpAndSettle(); // Wait for animation to finish
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListOfNotes, 'Test delete note!'), findsNothing);
    expect(find.byType(NoteScreen), findsNothing);
  });

  testWidgets('Logout changes to auth screen', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('Settings changes to settings screen',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1000);
    MockRealmDB mockDb = MockRealmDB();
    when(() => mockDb.getSearchNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    when(() => mockDb.getBacklinkNotes(any()))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: MyHomePage(db: mockDb)));
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(MyHomePage), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
