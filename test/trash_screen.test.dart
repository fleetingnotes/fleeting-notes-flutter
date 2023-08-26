import 'package:fleeting_notes_flutter/screens/trash/trash_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'utils.dart';

void main() {
  group('Trash Screen Tests', () {
    testWidgets('Show empty trash if there are no deleted notes',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      expect(find.byType(MainScreen), findsOneWidget);
      await navigateToTrash(tester);
      expect(find.byType(TrashScreen), findsOneWidget);
      expect(find.byType(NoteCard), findsNothing);
      expect(find.text('Deleted Notes'), findsOneWidget);
    });

    testWidgets('Delete note and show it in trash',
        (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: 'Test delete note!', closeDialog: true);
      expect(find.byType(NoteCard), findsOneWidget);
      await tester.tap(find.text('Test delete note!', findRichText: true));
      await tester.pumpAndSettle();
      await deleteCurrentNote(tester);
      expect(find.byType(NoteCard), findsNothing);
      await navigateToTrash(tester);
      expect(
          find.text('Test delete note!', findRichText: true), findsOneWidget);
    });

    testWidgets('Restore a deleted note', (WidgetTester tester) async {
      await fnPumpWidget(tester, const MyApp());
      await addNote(tester, content: 'Test delete note!', closeDialog: true);
      await tester.tap(find.text('Test delete note!', findRichText: true));
      await tester.pumpAndSettle();
      await deleteCurrentNote(tester);
      await navigateToTrash(tester);
      await tester.tap(find.text('Test delete note!', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to restore this note?'),
          findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.byType(MainScreen), findsOneWidget);
      expect(
          find.text('Test delete note!', findRichText: true), findsOneWidget);
    });
  });
}
