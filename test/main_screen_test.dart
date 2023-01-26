import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/components/side_rail.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:go_router/go_router.dart';

import 'utils.dart';

// Currently Only Testing Web
void main() {
  // Desktop / Tablet Tests
  testWidgets('Render Main Screen (Desktop/Tablet)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(SideRail), findsOneWidget);
    expect(find.byType(NoteCard), findsNothing);
    final BuildContext context = tester.element(find.byType(MainScreen));
    expect(GoRouter.of(context).location == '/', isTrue);
  });

  testWidgets('Press new note button adds new note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    final BuildContext context = tester.element(find.byType(MainScreen));
    expect(GoRouter.of(context).location.startsWith('/note/'), isTrue);
  });

  testWidgets('Clicking NoteCard populates NoteEditor and sets active note',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Click me note!');
    await tester.tap(find.descendant(
        of: find.byType(SearchScreen), matching: find.byType(NoteCard)));
    await tester.pumpAndSettle(); // Wait for animation to finish
    final BuildContext context = tester.element(find.byType(MainScreen));
    expect(
        tester
            .widget<Card>(find.ancestor(
              of: find.text('Click me note!', findRichText: true),
              matching: find.byType(Card),
            ))
            .color,
        Theme.of(context).colorScheme.surfaceVariant);
    expect(
        find.descendant(
            of: find.byType(NoteEditor),
            matching: find.text('Click me note!', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Save note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Test save note!');
    expect(
        find.descendant(
            of: find.byType(NoteCard),
            matching: find.text('Test save note!', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Delete note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Test delete note!');
    await tester.tap(find.descendant(
        of: find.byType(NoteCard),
        matching: find.text('Test delete note!', findRichText: true)));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await deleteCurrentNote(tester);
    expect(find.byType(NoteCard), findsNothing);
  });

  // // // Mobile Tests
  testWidgets('Render Main Screen (Mobile)', (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(NoteEditor), findsNothing);
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Adding a note navigates to NoteEditor (Mobile)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(SearchScreen), findsOneWidget);
    await addNote(tester, content: 'Click me note!');
    expect(find.widgetWithText(NoteEditor, 'Click me note!'), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);
  });

  // // // Responsive Tests
  testWidgets('Resize Desktop (note + search empty) -> Mobile (note)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'test');

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsNothing);
    expect(find.byType(NoteEditor), findsOneWidget);
  });

  testWidgets('Resize Desktop (note + search) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'test');
    await searchNotes(tester, 'test');

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });

  testWidgets('Resize Desktop (search empty + note empty) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
  });

  testWidgets('Resize Mobile (search empty) -> Desktop (search + note)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
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
    await fnPumpWidget(tester, const MyApp());

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
      const MaterialApp(home: MyApp()),
    );
    await goToNewNote(tester, content: 'init note');

    // Mobile on Note Screen
    expect(find.text('init note'), findsOneWidget);
  });

  testWidgets('When Desktop Size with initial note, Then see init note',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(
      tester,
      const MyApp(),
    );
    await goToNewNote(tester, content: 'init note');
    expect(find.text('init note'), findsOneWidget);
  });
  testWidgets('When Desktop Size with initial note from query params',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(
      tester,
      const MyApp(),
    );
    final BuildContext context = tester.element(find.byType(MainScreen));
    context.goNamed('home', queryParams: {'content': 'init note'});
    await tester.pumpAndSettle();
    expect(find.text('init note'), findsOneWidget);
  });
}
