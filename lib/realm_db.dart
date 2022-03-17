import 'dart:io';

import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as Path;

class RealmDB {
  RealmDB({required this.app});

  final RealmApp app;
  final MongoRealmClient client = MongoRealmClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController streamController = StreamController();
  static const storage = FlutterSecureStorage();
  String? _email;
  String? _password;
  String? _token;
  String apiUrl =
      'https://realm.mongodb.com/api/client/v2.0/app/fleeting-notes-knojs/';
  String endpointUrl =
      'https://data.mongodb-api.com/app/fleeting-notes-knojs/endpoint/';
  Dio dio = Dio();

  Future<List<Note>> getSearchNotes(queryRegex) async {
    String escapedQuery = '';
    queryRegex.runes.forEach((int rune) {
      var character = String.fromCharCode(rune);
      if (character.contains(RegExp('[a-zA-Z0-9]'))) {
        escapedQuery += character;
      } else {
        escapedQuery += '\\$character';
      }
    });
    var notesStr = await getAllNotes();

    return notesStr;
    // return jsonStringToNote(notesStr);
  }

  Future<List<Note>> getAllNotes() async {
    try {
      var url = Path.join(apiUrl, 'graphql');
      var query =
          '{"query":"query {  notes(query: {_isDeleted_ne: true}) {_id  title  content  source  timestamp}}"}';
      var res = await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          "Authorization": "Bearer $_token",
        }),
        data: query,
      );
      List<Note> notes = [];
      var noteMapList = jsonDecode(res.toString())['data']['notes'];
      noteMapList.forEach((noteMap) {
        notes.add(Note.fromMap(noteMap));
      });
      return notes;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Note>> queryNotes(
      RegExp title, RegExp content, RegExp source) async {
    return await getAllNotes();
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

  Future<List> getAllLinks() async {
    var notesStr = await client.callFunction("findAllLinks");
    return notesStr;
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
      "source": note.source,
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
    collection.updateOne(
      filter: {"_id": note.id},
      update: UpdateOperator.set({
        "source": note.source,
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
    _email = null;
    _password = null;
  }

  Future<bool> loginWithStorage() async {
    String? email;
    String? password;
    try {
      email = await storage.read(key: 'email');
      password = await storage.read(key: 'password');
    } catch (e) {
      print(e);
      return false;
    }

    if (email == null || password == null) {
      return false;
    }
    bool validCredentials = await checkAndSetCredentials(email, password);
    return validCredentials;
  }

  Future<bool> login(String email, String password) async {
    await storage.write(key: 'email', value: email);
    await storage.write(key: 'password', value: password);
    bool validCredentials = await checkAndSetCredentials(email, password);
    return validCredentials;
  }

  Future<bool> checkAndSetCredentials(String email, String password) async {
    try {
      var authUrl = Path.join(apiUrl, 'auth/providers/local-userpass/login');
      var res = await Dio().post(
        authUrl,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          "username": email,
          "password": password,
        }),
      );
      _email = email;
      _password = password;
      _token = res.data['access_token'];
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Note>> getBacklinkNotes(Note note) async {
    // var notesStr =
    //     await client.callFunction("getBacklinkNotes", args: [note.title]);
    // var notesStr =
    //     await callFunctionEndpoint("getBacklinkNotes", data: note.title);
    // return jsonStringToNote(notesStr);
    return [];
  }

  void navigateToSearch(String query) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => SearchScreen(
          query: query,
          db: this,
        ),
        transitionsBuilder: _transitionBuilder,
      ),
    );
  }

  SlideTransition _transitionBuilder(
      context, animation, secondaryAnimation, child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  void navigateToNote(Note note) {
    navigatorKey.currentState!.push(PageRouteBuilder(
      pageBuilder: (context, _, __) => NoteScreen(db: this, note: note),
      transitionsBuilder: _transitionBuilder,
    ));
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void listenNoteChange(Function callback) {
    unlistenNoteChange();
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

  static Note mongoDocToNote(MongoDocument mongoDoc) {
    var note = Note(
      id: mongoDoc.get("_id").toString(),
      title: mongoDoc.get("title").toString(),
      content: mongoDoc.get("content").toString(),
      source: mongoDoc.get("source").toString(),
      timestamp: mongoDoc.get("timestamp").toString(),
    );

    return note;
  }
}
