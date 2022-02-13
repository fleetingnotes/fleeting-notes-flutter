import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'models/Note.dart';

class RealmDB {
  // TODO: pass collection as parameter
  RealmDB({required this.collection});

  final MongoCollection collection;
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<List<Note>> getNotes() async {
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

  void navigateToNote(Note note) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
          pageBuilder: (context, _, __) => NoteScreen(db: this, note: note)),
    );
  }

  void popAllRoutes() {
    navigatorKey.currentState!.popUntil((route) => false);
  }
}
