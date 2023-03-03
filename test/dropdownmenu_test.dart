import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

// dropdownbutton tests need to be isolated for some reason
void main() {
  testWidgets('Notes are sorted by modified time', (WidgetTester tester) async {
    List<String> noteContentList = ['1', '2', '3', '4', '5'];
    await fnPumpWidget(tester, const MyApp());
    for (var content in noteContentList) {
      await addNote(tester, content: content, closeDialog: true);
    }

    List<String> orderedContentList = getContentNoteCardList(tester);
    expect(listEquals(orderedContentList, ['5', '4', '3', '2', '1']), isTrue);

    // modify middle note
    await tester.tap(find.text('3', findRichText: true));
    await tester.pumpAndSettle();
    await modifyCurrentNote(tester, content: '3 - modified', closeDialog: true);

    // sort by modified and check
    await sortBy(tester, "Modified At", asc: false);
    orderedContentList = getContentNoteCardList(tester);
    expect(listEquals(orderedContentList, ['3 - modified', '5', '4', '2', '1']),
        isTrue);
  });
}
