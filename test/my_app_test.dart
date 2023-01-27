import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Settings changes to settings screen',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    expect(find.byType(MainScreen), findsOneWidget);
    await navigateToSettings(tester);
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Login has different notes', (WidgetTester tester) async {
    resizeToDesktop(tester);
    var mockSupabase = getBaseMockSupabaseDB();
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await addNote(tester);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byIcon(Icons.arrow_back),
    ));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
          of: find.byType(SearchScreen),
          matching: find.byType(NoteCard),
        ),
        findsNothing);
  });

  testWidgets('Login and logout does not delete notes',
      (WidgetTester tester) async {
    resizeToDesktop(tester);
    var mockSupabase = getBaseMockSupabaseDB();
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await addNote(tester);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    await tester.tap(find.text('Logout'));
    await tester.tap(find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byIcon(Icons.arrow_back),
    ));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
          of: find.byType(SearchScreen),
          matching: find.byType(NoteCard),
        ),
        findsOneWidget);
  });
}
