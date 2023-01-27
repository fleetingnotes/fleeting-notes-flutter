// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
    registerFallbackValue(SearchQuery(query: ''));
  });

  testWidgets('Render List of Notes', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('Test search filters properly', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester, content: 'hello');
    await addNote(tester, content: 'world');

    expect(find.byType(NoteCard), findsNWidgets(2));
    await tester.enterText(findSearchbar(tester), 'hello');
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('Test filter button opens search dialog',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await tester.tap(findSearchbar(tester));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.byType(SearchDialog), findsOneWidget);
  });

  testWidgets('When search by dialog has all unchecked boxes, then no notes',
      (WidgetTester tester) async {},
      skip: true);

  testWidgets('When we sort by anything, then notes are sorted',
      (WidgetTester tester) async {},
      skip: true);
}
