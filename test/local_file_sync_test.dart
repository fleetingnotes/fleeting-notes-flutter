import 'dart:io';

import 'package:file/file.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mocks/mock_database.dart';
import 'mocks/mock_local_file_sync.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

void main() {
  group("Changing local notes", () {
    testWidgets("Adding note creates a file", (WidgetTester tester) async {
      var settings = MockSettings();
      var lfs = await setupLfs(settings: settings);
      await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
          settings: settings, localFs: lfs);

      expect(lfs.fs.directory(lfs.syncDir).listSync().isEmpty, isTrue);
      await addNote(tester, title: "hello-world");
      expect(lfs.fs.directory(lfs.syncDir).listSync().length == 1, isTrue);
      expect(
        lfs.fs.directory(lfs.syncDir).listSync().first.basename ==
            'hello-world.md',
        isTrue,
      );
    });
    testWidgets(
      "Updating the content of the note updates file contents",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world");

        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
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

        expect(lfs.fs.directory(lfs.syncDir).listSync().isEmpty, isFalse);
        await deleteCurrentNote(tester);
        expect(lfs.fs.directory(lfs.syncDir).listSync().isEmpty, isTrue);
      },
    );
    testWidgets(
      "Local changes update renamed file",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world", content: "");

        expect(find.byType(NoteCard), findsOneWidget);
        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
        var newPath =
            file.path.replaceFirst('hello-world.md', 'hello-world-mod.md');
        renameFile(file, lfs, newPath);
        await modifyCurrentNote(tester, content: 'a modification');
        expect(
          lfs.fs.file(newPath).readAsStringSync().contains("a modification"),
          isTrue,
        );
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
        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
        String fileContents = file.readAsStringSync();
        await deleteCurrentNote(tester);
        file.writeAsStringSync(fileContents);
        // lfs.dirController.add(WatchEvent(ChangeType.ADD, file.path));
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
        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
        appendFile(file, lfs, "a modification");
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
        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
        deleteFile(file, lfs);
        await tester.pumpAndSettle();
        expect(find.byType(NoteCard), findsNothing);
      },
    );
    testWidgets(
      "Renaming from filesystem notes still updates",
      (WidgetTester tester) async {
        var settings = MockSettings();
        var lfs = await setupLfs(settings: settings);
        await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
            settings: settings, localFs: lfs);
        await addNote(tester, title: "hello-world", content: "");

        expect(find.byType(NoteCard), findsOneWidget);
        File file = lfs.fs.directory(lfs.syncDir).listSync().first as File;
        var newPath =
            file.path.replaceFirst('hello-world.md', 'hello-world-mod.md');
        renameFile(file, lfs, newPath);
        appendFile(lfs.fs.file(newPath), lfs, "a modification");
        await tester.pumpAndSettle();
        expect(
            find.descendant(
                of: find.bySemanticsLabel('Note and links to other ideas'),
                matching: find.text('a modification', findRichText: true)),
            findsOneWidget);
      },
    );
  });
  group("Init local file sync", () {
    Future<File> setupInitLFS(
        WidgetTester tester, DateTime fileLastModified) async {
      // setup mocks
      var settings = MockSettings();
      var lfs = await setupLfs(settings: settings);
      var supabase = getBaseMockSupabaseDB();
      var db = MockDatabase(
          supabase: supabase, settings: settings, localFileSync: lfs);

      // setup notes
      var n = Note.empty(title: "hello-world", content: "local mod");
      var file = lfs.fs.file(p.join(lfs.syncDir, "${n.title}.md"));
      file.writeAsStringSync(
          n.getMarkdownContent().replaceFirst("local mod", "filesystem mod"));
      file.setLastModifiedSync(fileLastModified);
      await tester.pump(const Duration(seconds: 1));
      await db.upsertNotes([n]);
      await lfs.init(notes: await db.getAllNotes()); // run sync

      await fnPumpWidget(tester, const MaterialApp(home: MainScreen()),
          settings: settings, localFs: lfs, db: db);
      return file;
    }

    testWidgets(
      "Prioritizes local if modified last",
      (WidgetTester tester) async {
        var fileLastModified = DateTime.now().subtract(const Duration(days: 1));
        var file = await setupInitLFS(tester, fileLastModified);
        await tester.tap(find.byType(NoteCard));
        await tester.pumpAndSettle();
        expect(
            find.descendant(
                of: find.bySemanticsLabel('Note and links to other ideas'),
                matching: find.text('local mod', findRichText: true)),
            findsOneWidget);

        expect(file.readAsStringSync().contains('local mod'), isTrue);
      },
    );
    testWidgets(
      "Prioritizes filesystem if modified last",
      (WidgetTester tester) async {
        var fileLastModified = DateTime.now().add(const Duration(days: 1));
        var file = await setupInitLFS(tester, fileLastModified);

        await tester.tap(find.byType(NoteCard));
        await tester.pumpAndSettle();
        expect(
            find.descendant(
                of: find.bySemanticsLabel('Note and links to other ideas'),
                matching: find.text('filesystem mod', findRichText: true)),
            findsOneWidget);

        expect(file.readAsStringSync().contains('filesystem mod'), isTrue);
      },
    );
  });
}

void deleteFile(File file, MockLocalFileSync lfs) {
  file.deleteSync();
  var e = MockFileSystemEvent();
  when(() => e.path).thenReturn(file.path);
  when(() => e.type).thenReturn(FileSystemEvent.delete);
  lfs.dirController.add(e);
}

void appendFile(File file, MockLocalFileSync lfs, String appendText) {
  file.writeAsStringSync(appendText, mode: FileMode.append);
  var e = MockFileSystemEvent();
  when(() => e.path).thenReturn(file.path);
  when(() => e.type).thenReturn(FileSystemEvent.modify);
  lfs.dirController.add(e);
}

void addFile(File file, MockLocalFileSync lfs, String fileContents) {
  file.writeAsStringSync(fileContents);
  var e = MockFileSystemEvent();
  when(() => e.path).thenReturn(file.path);
  when(() => e.type).thenReturn(FileSystemEvent.modify);
  lfs.dirController.add(e);
}

void renameFile(File file, MockLocalFileSync lfs, String destination) {
  file.renameSync(destination);
  var e = MockFileSystemMoveEvent();
  when(() => e.path).thenReturn(file.path);
  when(() => e.type).thenReturn(FileSystemEvent.move);
  when(() => e.destination).thenReturn(destination);
  lfs.dirController.add(e);
}

class MockFileSystemEvent extends Mock implements FileSystemEvent {}

class MockFileSystemMoveEvent extends Mock implements FileSystemMoveEvent {}
