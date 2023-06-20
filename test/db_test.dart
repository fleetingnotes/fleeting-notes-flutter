import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mocks/mock_box.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';

var settings = MockSettings();
var mockBox = MockBox();
String uuid = "07666b8a-2a65-4556-8696-b81505829910";

class MockDatabaseTests extends Database {
  MockDatabaseTests()
      : super(
            supabase: getBaseMockSupabaseDB(),
            settings: settings,
            localFileSync: LocalFileSync(settings: settings));

  Note newNote(String id, title, content, source) {
    var note = Note.empty(
      id: uuid.replaceFirst('0', id),
      title: title,
      content: content,
      source: source,
    );
    return note;
  }

  @override
  Future<Box> getBox() async {
    return mockBox;
  }

  @override
  Future<List<Note>> getAllNotes({forceSync = false}) {
    return Future.value([
      newNote('1', 'title', 'content', 'source'),
      newNote('2', '', 'title in content', ''),
      newNote('3', '', 'some text and a [[link]]', ''),
      newNote('4', '', '#tag1 some content #tag2', ''),
    ]);
  }
}

void main() {
  group("getSearchNotes", () {
    var inputsToExpected = {
      'title': ['1', '2'],
      'content': ['1', '2', '4'],
      'source': ['1'],
      '#tag1 #tag2': [],
      '[[link]]': ['3'],
      'title content': [],
    };
    inputsToExpected.forEach((query, noteIds) {
      test('query: $query -> note_ids: $noteIds', () async {
        final db = MockDatabaseTests();
        List<Note> searchedNotes =
            await db.getSearchNotes(SearchQuery(query: query));
        List searchedIds =
            searchedNotes.map((n) => n.id.characters.first).toList();
        expect(searchedIds.length, noteIds.length);
        expect(searchedIds.toSet(), noteIds.toSet());
      });
    });
  });
  group("getNoteByTitle", () {
    var inputsToExpected = {
      'title': '1',
      'content': null,
      'link': null,
    };
    inputsToExpected.forEach((query, noteId) {
      test('query: $query -> note_id: $noteId', () async {
        final db = MockDatabaseTests();
        Note? note = await db.getNoteByTitle(query);
        expect(note?.id.characters.first, noteId);
      });
    });
  });
  group("titleExists", () {
    var inputsToExpected = {
      ['0', 'title']: true,
      ['1', 'title']: false,
      ['69', 'link']: false,
    };
    inputsToExpected.forEach((params, isExists) {
      test('params: $params -> isExists: $isExists', () async {
        var noteId = uuid.replaceFirst('0', params[0]);
        final db = MockDatabaseTests();
        bool? actualIsExists = await db.titleExists(noteId, params[1]);
        expect(actualIsExists, isExists);
      });
    });
  });

  test('getAllLinks', () async {
    final db = MockDatabaseTests();
    List allLinks = await db.getAllLinks();
    expect(allLinks, ['title', 'link']);
  });

  test('getAllLocalNotes works with non-Note type', () async {
    final db = MockDatabaseTests();
    var box = await db.getBox();
    await box.put('random-val', 'asdf');
    await box.put('note', Note.empty());
    var notes = db.getAllNotesLocal(box);
    expect(notes.length == 1, isTrue);
  });

  group("noteExists", () {
    final db = MockDatabaseTests();
    var inputsToExpected = {
      db.newNote('1', 'title', 'content', 'source'): true,
      db.newNote('1', '', '', ''): true,
      db.newNote('0', 'title', 'content', 'source'): false,
    };
    inputsToExpected.forEach((note, isExists) {
      test('query: $note -> note_id: $isExists', () async {
        bool? actualIsExists = await db.noteExists(note);
        expect(actualIsExists, isExists);
      });
    });
  }, skip: true);
}
