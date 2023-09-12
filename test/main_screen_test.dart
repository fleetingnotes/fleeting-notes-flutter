import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/components/side_rail.dart';
import 'package:fleeting_notes_flutter/screens/note/components/CheckListField/check_list_field.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_bar.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/one_account_dialog.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/widgets/record_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

// Currently Only Testing Web
void main() {
  // Desktop / Tablet Tests
  testWidgets('Render Main Screen (Desktop/Tablet)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(NoteEditor), findsNothing);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(SideRail), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
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

  testWidgets('Clicking NoteCard opens Note Editor',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Click me note!', closeDialog: true);
    await tester.tap(find.descendant(
        of: find.byType(SearchScreen), matching: find.byType(NoteCard)));
    await tester.pumpAndSettle(); // Wait for animation to finish
    expect(
        find.descendant(
            of: find.byType(NoteEditor),
            matching: find.text('Click me note!', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Going to main screen with unsaved note saves note',
      (WidgetTester tester) async {
    var settings = MockSettings();
    // Setting unsaved note
    await settings.set('unsaved-note', Note.empty(content: 'content'));

    await fnPumpWidget(tester, const MyApp(), settings: settings);
    expect(
        find.descendant(
            of: find.byType(NoteCard),
            matching: find.text('content', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Save note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Test save note!', closeDialog: true);
    expect(
        find.descendant(
            of: find.byType(NoteCard),
            matching: find.text('Test save note!', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('Delete note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Test delete note!', closeDialog: true);
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.tap(find.text('Test delete note!', findRichText: true));
    await tester.pumpAndSettle();
    await deleteCurrentNote(tester);
    expect(find.byType(NoteCard), findsNothing);
  });

  // // // Mobile Tests
  testWidgets('Render Main Screen (Mobile)', (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.text('New note'), findsNothing);
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Adding a note navigates to NoteEditor (Mobile)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Click me note!');
    expect(find.widgetWithText(NoteEditor, 'Click me note!'), findsOneWidget);
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
    expect(find.byIcon(Icons.tune), findsNothing);
  });

  testWidgets('Resize Desktop (note + search) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'note', closeDialog: true);
    await searchNotes(tester, 'test');

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CustomSearchBar));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('Resize Desktop (search empty + note empty) -> Mobile (search)',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    await fnPumpWidget(tester, const MyApp());

    // Change to mobile
    resizeToMobile(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('New note'), findsNothing);
  });

  testWidgets('Resize Mobile (search empty) -> Desktop (search + note)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('New note'), findsNothing);

    // Change to Desktop
    resizeToDesktop(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
  });

  testWidgets('Resize Mobile (note) -> Desktop (search + note)',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());

    // Mobile on Note Screen
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('New note'), findsNothing);

    // Change to Desktop
    resizeToDesktop(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
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
    expect(find.byType(NoteEditor), findsOneWidget);
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
    expect(find.byType(NoteEditor), findsOneWidget);
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
  testWidgets('When Mobile Size with initial note from query params',
      (WidgetTester tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    final BuildContext context = tester.element(find.byType(MainScreen));
    context.goNamed('home', queryParams: {'content': 'init note'});
    await tester.pumpAndSettle();
    expect(find.text('init note'), findsOneWidget);
    expect(find.byType(NoteEditor), findsOneWidget);
  });

  // recovery dialog tests
  testWidgets('If no session dont see RecoverSessionDialog', (tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    expect(find.byType(OneAccountDialog), findsNothing);
  });
  testWidgets('If session and free tier, see RecoverSessionDialog',
      (tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getStoredSession())
        .thenAnswer((_) => Future.value(StoredSession(emptySession(), 'free')));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    expect(find.byType(OneAccountDialog), findsOneWidget);
  });
  testWidgets('If session and not free tier, attempt', (tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    var session = emptySession();
    when(() => mockSupabase.getStoredSession())
        .thenAnswer((_) => Future.value(StoredSession(session, null)));
    when(() => mockSupabase.recoverSession(session))
        .thenAnswer((_) => Future.value(RecoveredSessionEvent.succeeded));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    expect(find.byType(OneAccountDialog), findsNothing);
  });

  // test bottom app bar (on mobile)
  testWidgets('press record button opens dialog mobile', (tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(find.byIcon(Icons.mic_outlined));
    await tester.pump();
    expect(find.byType(RecordDialog), findsOneWidget);
  });

  testWidgets('press checklist button opens new note with checklist',
      (tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditor), findsOneWidget);
    expect(find.byType(ChecklistField), findsOneWidget);
  });

  testWidgets('press photo button opens pick image options', (tester) async {
    resizeToMobile(tester);
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(find.byIcon(Icons.photo_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(PickImageOptions), findsOneWidget);
  });

  testWidgets('Pin a note updates list of notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'Test pin note!', closeDialog: true);
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.tap(find.text('Test pin note!', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.byType(NoteCard), findsOneWidget);
  });
}
