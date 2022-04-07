// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
@TestOn('browser')
import 'package:fleeting_notes_flutter/screens/note/components/source_container_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });
  testWidgets('Empty source field shows Add Source Url',
      (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SourceContainer(controller: controller))));

    expect(find.text('Add Source URL'), findsOneWidget);
    expect(find.bySemanticsLabel('Source'), findsNothing);
  });

  testWidgets('Filled source shows Source field', (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    controller.text = 'filled';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SourceContainer(controller: controller))));

    expect(find.text('Add Source URL'), findsNothing);
    expect(find.bySemanticsLabel('Source'), findsOneWidget);
  });

  testWidgets('Clicking Add Source URL button shows follow-link button',
      (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SourceContainer(controller: controller))));

    await tester.tap(find.text('Add Source URL'));
    await tester.pump();

    expect(find.text('Add Source URL'), findsNothing);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('Empty Source Field has Follow Link Button disabled',
      (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SourceContainer(controller: controller))));

    await tester.tap(find.text('Add Source URL'));
    await tester.pump();
    expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                  of: find.byIcon(Icons.open_in_new),
                  matching:
                      find.byWidgetPredicate((widget) => widget is IconButton)),
            )
            .onPressed,
        isNull);
  });
}
