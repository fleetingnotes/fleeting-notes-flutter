// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

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
  });

  testWidgets('Render List of Notes', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(3000, 1500);
    MockDatabase mockDb = MockDatabase();
    when(() => mockDb.getSearchNotes('', forceSync: any(named: 'forceSync')))
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
    when(() => mockDb.getSearchNotes('', forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([Note.empty()]));
    when(() =>
            mockDb.getSearchNotes('hello', forceSync: any(named: 'forceSync')))
        .thenAnswer((_) async => Future.value([]));
    await tester.pumpWidget(MaterialApp(home: SearchScreen(db: mockDb)));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Search'), 'hello');
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsNothing);
  });
}
