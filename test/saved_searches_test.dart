import 'package:fleeting_notes_flutter/screens/main/components/create_search_dialog.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'mocks/mock_settings.dart';
import 'utils.dart';

void main() {
  group('Saved Searches Tests', () {
    testWidgets('Create a new search', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      expect(find.byType(MainScreen), findsOneWidget);
      await navigateToCreateEditSearchesDialog(tester);
      expect(find.byType(CreateSearchDialog), findsOneWidget);
      final textFieldFinder =
          find.widgetWithText(TextField, 'Create new search');
      await tester.enterText(textFieldFinder, "important");
      await tester.pumpAndSettle();
      final iconAddFinder = find.descendant(
        of: find.byType(IconButton), // Find the parent Row
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(iconAddFinder);
      await tester.pumpAndSettle();

      expect(find.text('important'), findsNWidgets(2));
      final iconCloseFinder = find.descendant(
        of: find.byType(IconButton), // Find the parent Row
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(iconCloseFinder);
      await tester.pumpAndSettle();
      expect(find.text('important'), findsOneWidget);
    });

    testWidgets('Delete a search', (WidgetTester tester) async {
      var settings = MockSettings();
      List<String> list = ['important'];
      await settings.set('historical-searches', list);
      await fnPumpWidget(tester, const MyApp(), settings: settings);
      expect(find.byType(MainScreen), findsOneWidget);
      await navigateToCreateEditSearchesDialog(tester);
      expect(find.byType(CreateSearchDialog), findsOneWidget);
      final rowFinder = find.descendant(
        of: find.byType(DynamicDialog), // Find the parent Row
        matching: find.text('important'),
      );
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      final iconDeleteFinder = find.descendant(
        of: find.byType(IconButton), // Find the parent Row
        matching: find.byIcon(Icons.delete),
      );
      await tester.tap(iconDeleteFinder);
      await tester.pumpAndSettle();
      final iconCloseFinder = find.descendant(
        of: find.byType(IconButton), // Find the parent Row
        matching: find.byIcon(Icons.close),
      );
      expect(find.text('important'), findsNothing);

      await tester.tap(iconCloseFinder);
      await tester.pumpAndSettle();

      expect(find.text('important'), findsNothing);
    });

    testWidgets('Edit a search', (WidgetTester tester) async {
      var settings = MockSettings();
      List<String> list = ['important'];
      await settings.set('historical-searches', list);
      await fnPumpWidget(tester, const MyApp(), settings: settings);
      expect(find.byType(MainScreen), findsOneWidget);
      await navigateToCreateEditSearchesDialog(tester);
      expect(find.byType(CreateSearchDialog), findsOneWidget);
      final rowFinder = find.descendant(
        of: find.byType(DynamicDialog), // Find the parent Row
        matching: find.text('important'),
      );
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      final textFieldFinder = find.widgetWithText(TextField, 'important');
      await tester.enterText(textFieldFinder, "important new");
      final iconCheckFinder = find.descendant(
        of: find.byType(IconButton), // Find the parent Row
        matching: find.byIcon(Icons.check),
      );
      await tester.tap(iconCheckFinder);
      await tester.pumpAndSettle();
      expect(find.text('important new'), findsNWidgets(2));
    });

    testWidgets('Click in a saved search and show the notes filtered',
        (WidgetTester tester) async {
      var settings = MockSettings();
      List<String> list = ['important'];
      await settings.set('historical-searches', list);
      await fnPumpWidget(tester, const MyApp(), settings: settings);
      expect(find.byType(MainScreen), findsOneWidget);
      await addNote(tester,
          content: 'This is an important note!', closeDialog: true);
      await addNote(tester,
          content: 'This is another note!', closeDialog: true);
      expect(find.byType(NoteCard), findsNWidgets(2));
      final iconFinder = find.byIcon(Icons.menu);
      await tester.tap(iconFinder);
      await tester.pumpAndSettle();
      final parentInkWellFinder = find.ancestor(
        of: find.text('important'), // Widget inside the Expanded
        matching: find.byType(InkWell), // Parent InkWell
      );
      await tester.tap(parentInkWellFinder);
      await tester.pumpAndSettle();
      expect(find.byType(NoteCard), findsOneWidget);
    });
  });
}
