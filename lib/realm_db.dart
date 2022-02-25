import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';

class RealmDB {
  RealmDB({required this.app});

  final RealmApp app;
  final MongoRealmClient client = MongoRealmClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  StreamController streamController = StreamController();
  static const storage = FlutterSecureStorage();

  Future<List<Note>> getSearchNotes(queryRegex) async {
    var notesStr =
        await client.callFunction("getSearchNotes", args: [queryRegex]);
    return jsonStringToNote(notesStr);
  }

  Future<Note?> getNoteByTitle(title) async {
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    List<MongoDocument> docs = await collection.find(filter: {
      "title": title,
    });
    if (docs.isEmpty) {
      return null;
    }
    return mongoDocToNote(docs.first);
  }

  Future<bool> titleExists(id, title) async {
    MongoCollection collection =
        client.getDatabase("todo").getCollection("Note");
    List<MongoDocument> docs = await collection.find(filter: {
      "title": title,
      "_id": QueryOperator.ne(id),
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

  void upsertNote(Note note) async {
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

    // throws TypeError but insert still works...
    collection.insertOne(MongoDocument({
      "_id": note.id,
      "_partition": userId.toString(),
      "title": note.title,
      "content": note.content,
      "timestamp": note.timestamp,
      "_isDeleted": note.isDeleted,
    }));
  }

  void updateNote(Note note) {
    var collection = client.getDatabase("todo").getCollection("Note");
    // Can't update in both fields in one `updateOne` call
    collection.updateOne(
      filter: {"_id": note.id},
      update: UpdateOperator.set({
        "title": note.title,
      }),
    );
    collection.updateOne(
      filter: {"_id": note.id},
      update: UpdateOperator.set({
        "content": note.content,
      }),
    );
  }

  void deleteNote(Note note) {
    var collection = client.getDatabase("todo").getCollection("Note");
    collection.updateOne(
      filter: {"_id": note.id},
      update: UpdateOperator.set({
        "_isDeleted": true,
      }),
    );
  }

  Future<bool> registerUser(String email, String password) async {
    return await app.registerUser(email, password);
  }

  void logout() async {
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
    await app.logout();
  }

  Future<CoreRealmUser?> loginWithStorage() async {
    String? email;
    String? password;
    try {
      email = await storage.read(key: 'email');
      password = await storage.read(key: 'password');
    } catch (e) {
      print(e);
      return null;
    }

    if (email == null || password == null) {
      return null;
    }
    return app.login(Credentials.emailPassword(email, password));
  }

  Future<CoreRealmUser?> login(String email, String password) async {
    await storage.write(key: 'email', value: email);
    await storage.write(key: 'password', value: password);
    var user = await app.login(Credentials.emailPassword(email, password));
    return user;
  }

  Future<List<Note>> getBacklinkNotes(Note note) async {
    var notesStr =
        await client.callFunction("getBacklinkNotes", args: [note.title]);
    return jsonStringToNote(notesStr);
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

  void unlistenNoteChange() {
    streamController.close();
    streamController = StreamController();
  }

  void popAllRoutes() {
    navigatorKey.currentState!.popUntil((route) => false);
  }

  static List<Note> jsonStringToNote(String jsonString) {
    var noteList = jsonDecode(jsonString);
    var notes = noteList.map((item) {
      return Note(
        id: item["_id"].toString(),
        title: item["title"].toString(),
        content: item["content"].toString(),
        timestamp: item["timestamp"].toString(),
      );
    }).toList();

    return List<Note>.from(notes);
  }

  static Note mongoDocToNote(MongoDocument mongoDoc) {
    var note = Note(
      id: mongoDoc.get("_id").toString(),
      title: mongoDoc.get("title").toString(),
      content: mongoDoc.get("content").toString(),
      timestamp: mongoDoc.get("timestamp").toString(),
    );

    return note;
  }
}
