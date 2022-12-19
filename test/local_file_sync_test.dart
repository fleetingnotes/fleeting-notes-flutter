import 'package:file/file.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watcher/watcher.dart';
import 'mocks/mock_settings.dart';
// import 'package:path/path.dart' as p;
import 'utils.dart';

void main() {
  group("Changing local notes", () {
    testWidgets("Adding note creates a file", (WidgetTester tester) async {
      var settings = MockSettings();
      var lfs = await setupLfs(settings: settings);
      await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
          settings: settings, localFs: lfs);

      expect(lfs.fs.currentDirectory.listSync().isEmpty, isTrue);
      await addNote(tester, title: "hello-world");
      expect(lfs.fs.currentDirectory.listSync().length == 1, isTrue);
      expect(
          lfs.fs.currentDirectory.listSync().first.basename == 'hello-world.md',
          isTrue);
    });
    testWidgets(
      "Updating the content of the note updates file contents",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world");

        File file = lfs.fs.currentDirectory.listSync().first as File;
        expect(file.readAsStringSync().contains("a modification"), isFalse);
        await modifyCurrentNote(tester, content: "a modification");
        expect(file.readAsStringSync().contains("a modification"), isTrue);
      },
    );
    testWidgets(
      "Deleting a note deletes the file",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world");

        expect(lfs.fs.currentDirectory.listSync().isEmpty, isFalse);
        await deleteCurrentNote(tester);
        expect(lfs.fs.currentDirectory.listSync().isEmpty, isTrue);
      },
    );
  });
  group("Changing filesystem notes", () {
    testWidgets(
      "Adding filesystem notes do not create new notes",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world", content: "");

        expect(find.byType(NoteCard), findsOneWidget);
        File file = lfs.fs.currentDirectory.listSync().first as File;
        String fileContents = file.readAsStringSync();
        await deleteCurrentNote(tester);
        file.writeAsStringSync(fileContents);
        lfs.dirController.add(WatchEvent(ChangeType.ADD, "/hello-world.md"));
        await tester.pumpAndSettle();
        expect(find.byType(NoteCard), findsNothing);
      },
    );
    testWidgets(
      "Updating filesystem notes updates current notes",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world", content: "");

        expect(find.byType(NoteCard), findsOneWidget);
        File file = lfs.fs.currentDirectory.listSync().first as File;
        file.writeAsStringSync("a modification", mode: FileMode.append);
        lfs.dirController.add(WatchEvent(ChangeType.MODIFY, "/hello-world.md"));
        await tester.pumpAndSettle();
        expect(
            find.descendant(
                of: find.bySemanticsLabel('Note and links to other ideas'),
                matching: find.text('a modification', findRichText: true)),
            findsOneWidget);
      },
    );
    testWidgets(
      "Removing filesystem notes removes current notes",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world", content: "");

        expect(find.byType(NoteCard), findsOneWidget);
        File file = lfs.fs.currentDirectory.listSync().first as File;
        file.deleteSync();
        lfs.dirController.add(WatchEvent(ChangeType.REMOVE, "/hello-world.md"));
        await tester.pumpAndSettle();
        expect(find.byType(NoteCard), findsNothing);
      },
    );
  });
}
