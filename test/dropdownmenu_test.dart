import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils.dart';

// dropdownbutton tests need to be isolated for some reason
void main() {
  testWidgets('Notes are sorted by modified time', (WidgetTester tester) async {
    List<String> noteContentList = ['1', '2', '3', '4', '5'];
    await fnPumpWidget(tester, const MaterialApp(home: MainScreen()));
    for (var content in noteContentList) {
      await addNote(tester, content: content);
    }

    List<String> orderedContentList = getContentNoteCardList(tester);
    expect(listEquals(orderedContentList, ['5', '4', '3', '2', '1']), isTrue);

    // modify middle note
    await tester.tap(find.text('3', findRichText: true));
    await tester.pumpAndSettle();
    await modifyCurrentNote(tester, content: '3 - modified');

    // sort by modified and check
    await sortBy(tester, "Sort by modified (new to old)");
    orderedContentList = getContentNoteCardList(tester);
    expect(listEquals(orderedContentList, ['3 - modified', '5', '4', '2', '1']),
        isTrue);
  });
}
