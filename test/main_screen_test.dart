// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
// @TestOn('browser')
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'mocks/mock_database.dart';

// Currently Only Testing Web
void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
    registerFallbackValue(SearchQuery(query: ''));
  });

  // Desktop / Tablet Tests
  // testWidgets('Render Main Screen (Desktop/Tablet)',
  //     (WidgetTester tester) async {
  //   // tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   // tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
  //   expect(find.byType(NoteEditor), findsOneWidget);
  //   expect(find.byType(SearchScreen), findsOneWidget);
  // });

  // testWidgets('Press new note button adds new note',
  //     (WidgetTester tester) async {
  //   // tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   // tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
  //   expect(find.byType(NoteEditor), findsNWidgets(1));
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();
  //   expect(find.byType(NoteEditor), findsNWidgets(2));
  // });

  testWidgets('Clicking NoteCard populates NoteScreen and sets active note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    // save note
    await tester.enterText(
        find.bySemanticsLabel('Note and links to other ideas'),
        'Click me note!');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(); // Wait for animation to finish
    await tester.pump(const Duration(seconds: 1)); // wait for notes to update
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

  // testWidgets('Save note updates list of notes', (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.titleExists(any(), any()))
  //       .thenAnswer((_) async => Future.value(false));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));
  //   await tester.enterText(
  //       find.bySemanticsLabel('Title of the idea'), 'Test save note!');
  //   await tester.pump();
  //   await tester.tap(find.text('Save'));
  //   await tester.pump();
  //   expect(
  //       find.widgetWithText(SearchScreen, 'Test save note!'), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsOneWidget);
  // }, skip: true);

  // testWidgets('Delete note updates list of notes', (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   Note newNote = Note.empty(content: 'Test delete note!');
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([newNote]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));
  //   await tester.pump();
  //   await tester.tap(find.widgetWithText(NoteCard, 'Test delete note!'));
  //   await tester.pumpAndSettle(); // Wait for animation to finish
  //   await tester.tap(find.byIcon(Icons.more_vert));
  //   await tester.pumpAndSettle();
  //   await tester.tap(find.text('Delete'));
  //   await tester.pumpAndSettle();
  //   expect(
  //       find.widgetWithText(SearchScreen, 'Test delete note!'), findsNothing);
  //   expect(find.byType(NoteEditor), findsNothing);
  // }, skip: true);

  // // Mobile Tests
  // testWidgets('Render Main Screen (Mobile)', (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));
  //   expect(find.byType(NoteEditor), findsNothing);
  //   expect(find.byType(SearchScreen), findsOneWidget);
  // });

  // testWidgets('Clicking NoteCard navigates to NoteScreen (Mobile)',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   Note newNote = Note.empty(content: 'Click me note!');
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([newNote]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   when((() => mockDb.upsertNote(any())))
  //       .thenAnswer((_) async => Future.value(true));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));
  //   await tester.pump();
  //   await tester.tap(find.text('Click me note!', findRichText: true));
  //   await tester.pumpAndSettle(); // Wait for animation to finish
  //   expect(find.widgetWithText(NoteEditor, 'Click me note!'), findsOneWidget);
  //   expect(find.byType(SearchScreen), findsNothing);
  // });

  // // Responsive Tests
  // testWidgets('Resize Desktop (note + search) -> Mobile (search)',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));

  //   // Change to mobile
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsNothing);
  // });

  // testWidgets('Resize Desktop (note + empty) -> Mobile (search)',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.deleteNotes(any()))
  //       .thenAnswer((_) async => Future.value(true));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));

  //   // Delete screen
  //   await tester.tap(find.byIcon(Icons.more_vert));
  //   await tester.pumpAndSettle();
  //   await tester.tap(find.text('Delete'));
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsNothing);

  //   // Change to mobile
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsNothing);
  // });

  // testWidgets('Resize Mobile (search) -> Desktop (search + note)',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));

  //   // Mobile on Search Screen
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsNothing);

  //   // Change to Desktop
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsOneWidget);
  // });

  // testWidgets('Resize Mobile (note) -> Desktop (search + note)',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   await tester.pumpWidget(const MaterialApp(home: MainScreen()));

  //   // Mobile on Note Screen
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsNothing);
  //   expect(find.byType(NoteEditor), findsOneWidget);

  //   // Change to Desktop
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   await tester.pumpAndSettle();
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsOneWidget);
  // });

  // testWidgets('When Mobile Size with initial note, Then see NoteEditor',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(300, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.upsertNote(any()))
  //       .thenAnswer((_) async => Future.value(true));
  //   await tester.pumpWidget(MaterialApp(
  //       home: MainScreen(initNote: Note.empty(content: 'init note'))));

  //   // Mobile on Note Screen
  //   expect(find.byType(SearchScreen), findsNothing);
  //   expect(find.byType(NoteEditor), findsOneWidget);
  //   expect(find.text('init note'), findsOneWidget);
  // });

  // testWidgets('When Desktop Size with initial note, Then see init note',
  //     (WidgetTester tester) async {
  //   tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
  //   tester.binding.window.devicePixelRatioTestValue = 1.0;
  //   MockDatabase mockDb = MockDatabase();
  //   when(() => mockDb.getAllLinks()).thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.isLoggedIn()).thenAnswer((_) => false);
  //   when(() => mockDb.getBacklinkNotes(any()))
  //       .thenAnswer((_) async => Future.value([]));
  //   when(() => mockDb.upsertNote(any()))
  //       .thenAnswer((_) async => Future.value(true));

  //   await tester.pumpWidget(MaterialApp(
  //       home: MainScreen(initNote: Note.empty(content: 'init note'))));

  //   // Mobile on Note Screen
  //   expect(find.byType(SearchScreen), findsOneWidget);
  //   expect(find.byType(NoteEditor), findsOneWidget);
  //   expect(find.text('init note'), findsOneWidget);
  // });
}
