import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('No Source Preview with invalid URL',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await goToNewNote(tester);
    expect(
        find.descendant(
            of: find.byType(NoteEditor), matching: find.byType(SourcePreview)),
        findsNothing);
  });

  testWidgets('No Source Preview with invalid URL',
      (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getUrlMetadata(any()))
        .thenAnswer((_) => Future.value(null));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await goToNewNote(tester);
    await tester.enterText(
        find.bySemanticsLabel('Source'), 'https://test.test');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(
        find.descendant(
            of: find.byType(NoteEditor), matching: find.byType(SourcePreview)),
        findsNothing);
  });

  testWidgets('Show source preview with proper URL',
      (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getUrlMetadata(any())).thenAnswer((_) =>
        Future.value(UrlMetadata(
            url: 'https://test.test',
            title: 'Test',
            description: 'Test',
            imageUrl: 'https://test.image/')));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await goToNewNote(tester, source: 'https://test.test');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(
        find.descendant(
            of: find.byType(NoteEditor), matching: find.byType(SourcePreview)),
        findsOneWidget);
  });

  testWidgets('Source preview must go through timer before loading',
      (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getUrlMetadata(any())).thenAnswer((_) =>
        Future.value(UrlMetadata(
            url: 'https://test.test',
            title: 'Test',
            description: 'Test',
            imageUrl: 'https://test.image/')));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await goToNewNote(tester);
    await tester.enterText(
        find.bySemanticsLabel('Source'), 'https://test.test');
    await tester.pumpAndSettle();
    expect(find.byType(SourcePreview), findsNothing);
  });
}
