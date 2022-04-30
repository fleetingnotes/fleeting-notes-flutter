// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'mock_database.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
    registerFallbackValue(SearchQuery(queryRegex: ''));
  });

  testWidgets('Render List of Notes', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([Note.empty()]));
    await tester.pumpWidget(MaterialApp(home: SearchScreen(db: mockDb)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('Test search filters properly', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getSearchNotes(SearchQuery(queryRegex: ''),
            forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([Note.empty()]));
    when(() => mockDb.getSearchNotes(SearchQuery(queryRegex: 'hello'),
            forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: SearchScreen(db: mockDb)));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Search'), 'hello');
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsNothing);
  }, skip: true);

  testWidgets('Test filter button opens search dialog',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getSearchNotes(any(), forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([Note.empty()]));
    await tester.pumpWidget(MaterialApp(home: SearchScreen(db: mockDb)));
    await tester.tap(find.byIcon(Icons.filter_list));
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
