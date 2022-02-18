import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';

class RealmDB {
  // TODO: pass collection as parameter
  RealmDB({required this.app});

  final RealmApp app;
  final MongoRealmClient client = MongoRealmClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  final StreamController streamController = StreamController();

  Future<List<Note>> getNotes() async {
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    List<MongoDocument> docs = await collection.find(
        filter: LogicalQueryOperator.or([
      {"_isDeleted": false},
      {"_isDeleted": QueryOperator.notExists()},
    ]));

    var notes = docs
        .map((item) => Note(
              id: item.get("_id").toString(),
              title: item.get("title").toString(),
              content: item.get("content").toString(),
            ))
        .toList();
    return notes;
  }

  Future<bool> titleExists(id, title) async {
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    List<MongoDocument> docs = await collection.find(filter: {
      "title": title,
      "_id": QueryOperator.ne(int.parse(id)),
    });

    return docs.isNotEmpty;
  }

  Future<bool> noteExists(Note note) async {
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    List<MongoDocument> docs = await collection.find(filter: {
      "_id": note.id,
    });

    return docs.isNotEmpty;
  }

  void upserNote(Note note) async {
    bool isNoteInDb = await noteExists(note);
    if (isNoteInDb) {
      updateNote(note);
    } else {
      insertNote(note);
    }
  }

  void insertNote(Note note) async {
    var collection = client.getDatabase("todo").getCollection("Note");
    var userId = await app.getUserId();
    var inserted = await collection.insertOne(MongoDocument({
      "_id": int.parse(note.id),
      "_partition": userId,
      "title": note.title,
      "content": note.content,
      "_isDeleted": note.isDeleted,
    }));
  }

  void updateNote(Note note) {
    var collection = client.getDatabase("todo").getCollection("Note");
    // Can't update in both fields in one `updateOne` call
    collection.updateOne(
      filter: {"_id": int.parse(note.id)},
      update: UpdateOperator.set({
        "title": note.title,
      }),
    );
    collection.updateOne(
      filter: {"_id": int.parse(note.id)},
      update: UpdateOperator.set({
        "content": note.content,
      }),
    );
  }

  void deleteNote(Note note) {
    var collection = client.getDatabase("todo").getCollection("Note");
    collection.updateOne(
      filter: {"_id": int.parse(note.id)},
      update: UpdateOperator.set({
        "_isDeleted": true,
      }),
    );
  }

  void logout() {
    app.logout();
  }

  Future<List<Note>> getBacklinkNotes(Note note) async {
    var notesStr =
        await client.callFunction("getBacklinkNotes", args: [note.title]);
    var noteList = jsonDecode(notesStr);
    var notes = noteList.map((item) {
      return Note(
        id: item["_id"].toString(),
        title: item["title"].toString(),
        content: item["content"].toString(),
      );
    }).toList();

    return List<Note>.from(notes);
  }

  void navigateToNote(Note note) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
          pageBuilder: (context, _, __) => NoteScreen(db: this, note: note)),
    );
  }

  void listenNoteChange(Function callback) {
    Stream stream = streamController.stream;
    stream.listen((note) {
      callback(note);
    });
  }

  void popAllRoutes() {
    navigatorKey.currentState!.popUntil((route) => false);
  }
}
