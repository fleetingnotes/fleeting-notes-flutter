// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_suggestions.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/textfield_toolbar.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/keyboard_button.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/textfield_toolbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('toolbar check', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await addNote(tester);
    await tester.tap(find.descendant(
        of: find.byType(ContentField), matching: find.byType(TextField)));
    await tester.pumpAndSettle();

    expect(
        find.descendant(
          of: find.byType(TextFieldToolbar),
          matching: find.byType(IconButton),
        ),
        findsNWidgets(2));
  });
}
