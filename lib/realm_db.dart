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
    List<MongoDocument> docs = await collection.find();

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
