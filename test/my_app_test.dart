import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Settings changes to settings screen',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1000, 500);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MainScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  }, skip: true);
}
