// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
// @TestOn('browser')
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';

import 'utils.dart';

// Currently Only Testing Web
void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
    registerFallbackValue(SearchQuery(query: ''));
  });

  // Desktop / Tablet Tests
  testWidgets('Render Main Screen (Desktop/Tablet)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Press new note button adds new note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.byType(NoteEditor), findsNWidgets(1));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.byType(NoteEditor), findsNWidgets(2));
  });

  testWidgets('Clicking NoteCard populates NoteScreen and sets active note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await addNote(tester, content: 'Click me note!');
    await tester.tap(find.descendant(
        of: find.byType(SearchScreen),
        matching: find.text(
          'Click me note!',
          findRichText: true,
        )));
    await tester.pumpAndSettle(); // Wait for animation to finish
    expect(
        tester
            .widget<NeumorphicButton>(find.descendant(
              of: find.byType(SearchScreen),
              matching: find.byType(NeumorphicButton),
            ))
            .style!
            .color,
        Colors.blue);
  });

  testWidgets('Save note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await addNote(tester, content: 'Test save note!');
    expect(
        find.descendant(
            of: find.byType(NoteCard),
            matching: find.text('Test save note!', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Delete note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    await addNote(tester, content: 'Test delete note!');
    expect(find.byType(NoteCard), findsOneWidget);
    await deleteCurrentNote(tester);
    expect(find.byType(NoteCard), findsNothing);
  });

  // // Mobile Tests
  testWidgets('Render Main Screen (Mobile)', (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.byType(NoteEditor), findsNothing);
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Clicking NoteCard navigates to NoteScreen (Mobile)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.byType(SearchScreen), findsOneWidget);
    await addNote(tester, content: 'Click me note!');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NoteCard));
    await tester.pumpAndSettle(); // Wait for animation to finish
    expect(find.widgetWithText(NoteEditor, 'Click me note!'), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);
  });

  // // Responsive Tests
  testWidgets('Resize Desktop (note + search) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });

  testWidgets('Resize Desktop (note + empty) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));

    // Delete screen
    await deleteCurrentNote(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });

  testWidgets('Resize Mobile (search) -> Desktop (search + note)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);

    // Change to Desktop
    resizeToDesktop(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsOneWidget);
  });

  testWidgets('Resize Mobile (note) -> Desktop (search + note)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));

    // Mobile on Note Screen
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsNothing);
    expect(find.byType(NoteEditor), findsOneWidget);

    // Change to Desktop
    resizeToDesktop(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsOneWidget);
  });

  testWidgets('When Mobile Size with initial note, Then see NoteEditor',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(
      tester,
      MaterialApp(home: MainScreen(initNote: Note.empty(content: 'init note'))),
    );

    // Mobile on Note Screen
    expect(find.byType(SearchScreen), findsNothing);
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.text('init note'), findsOneWidget);
  });

  testWidgets('When Desktop Size with initial note, Then see init note',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(
      tester,
      MaterialApp(home: MainScreen(initNote: Note.empty(content: 'init note'))),
    );

    // Mobile on Note Screen
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.text('init note'), findsOneWidget);
  });
}
