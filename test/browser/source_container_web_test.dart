// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
@TestOn('browser')
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import '../utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });
  testWidgets('Empty source field shows Add Source Url',
      (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    await fnPumpWidget(
        tester,
        MaterialApp(
            home: Scaffold(body: SourceContainer(controller: controller))));

    expect(find.text('Add Source URL'), findsOneWidget);
    expect(find.bySemanticsLabel('Source'), findsNothing);
  });

  testWidgets('Filled source shows Source field', (WidgetTester tester) async {
    TextEditingController controller = TextEditingController();
    controller.text = 'filled';
    await fnPumpWidget(
        tester,
        MaterialApp(
            home: Scaffold(body: SourceContainer(controller: controller))));

    expect(find.text('Add Source URL'), findsNothing);
    expect(find.bySemanticsLabel('Source'), findsOneWidget);
  });
}
