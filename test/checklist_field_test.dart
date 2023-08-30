import 'package:fleeting_notes_flutter/screens/note/components/CheckListField/check_list_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'mocks/mock_settings.dart';
import 'utils.dart';

void main() {
  group('ChecklistField Tests', () {
    testWidgets('adds unchecked items correctly', (WidgetTester tester) async {
      List<String> uncheckedItems = [];
      TextEditingController controller = TextEditingController();
      bool onChangedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistField(
              uncheckedItems: uncheckedItems,
              checkedItems: const [],
              controller: controller,
              onChanged: () {
                onChangedCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ChecklistField), findsOneWidget);
      expect(uncheckedItems.isEmpty, true);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Unchecked Item');

      expect(uncheckedItems.length, 1);
      expect(uncheckedItems[0], 'New Unchecked Item');

      expect(onChangedCalled, true);
    });
    testWidgets('removes unchecked items correctly',
        (WidgetTester tester) async {
      List<String> uncheckedItems = ['Item 1', 'Item 2', 'Item 3'];
      TextEditingController controller = TextEditingController();
      bool onChangedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistField(
              uncheckedItems: uncheckedItems,
              checkedItems: const [],
              controller: controller,
              onChanged: () {
                onChangedCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ChecklistField), findsOneWidget);
      expect(uncheckedItems.length, 3);

      await tester.tap(find.byIcon(Icons.close).at(1));
      await tester.pumpAndSettle();

      expect(uncheckedItems.length, 2);
      expect(uncheckedItems.contains('Item 2'), false);

      expect(onChangedCalled, true);
    });
  });

  group('Note checklist Tests', () {
    testWidgets('open checklist view if the note has checklist items',
        (WidgetTester tester) async {
      var settings = MockSettings();
      await fnPumpWidget(tester, const MyApp(), settings: settings);
      expect(find.byType(MainScreen), findsOneWidget);
      await addNote(tester, content: '- [ ] test\n', closeDialog: true);
      expect(find.byType(NoteCard), findsOneWidget);
      await tester.tap(find.byType(NoteCard));
      await tester.pumpAndSettle();
      expect(find.byType(ContentField), findsNothing);
      expect(find.byType(ChecklistField), findsOneWidget);
    });

    testWidgets('open default view if the note has not a valid checklist items',
        (WidgetTester tester) async {
      var settings = MockSettings();
      await fnPumpWidget(tester, const MyApp(), settings: settings);
      expect(find.byType(MainScreen), findsOneWidget);
      await addNote(tester,
          content: '- [ ] test\nrandom text', closeDialog: true);
      expect(find.byType(NoteCard), findsOneWidget);
      await tester.tap(find.byType(NoteCard));
      await tester.pumpAndSettle();
      expect(find.byType(ContentField), findsOneWidget);
      expect(find.byType(ChecklistField), findsNothing);
    });
  });
}
