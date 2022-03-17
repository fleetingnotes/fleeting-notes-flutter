import 'dart:html';
import 'dart:io';
import 'dart:math';

import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as Path;

class RealmDB {
  RealmDB({required this.app});

  final RealmApp app;
  final MongoRealmClient client = MongoRealmClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController streamController = StreamController();
  static const storage = FlutterSecureStorage();
  String? _userId;
  String? _token;
  DateTime _expirationDate = DateTime.now();
  String apiUrl =
      'https://realm.mongodb.com/api/client/v2.0/app/fleeting-notes-knojs/';
  Dio dio = Dio();

  Future<List<Note>> getSearchNotes(queryRegex) async {
    String escapedQuery =
        queryRegex.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
      return '\\${match.group(0)}';
    });
    RegExp r = RegExp(escapedQuery, multiLine: true);
    var allNotes = await getAllNotes();
    var notes = allNotes.where((note) {
      return r.hasMatch(note.title) ||
          r.hasMatch(note.content) ||
          r.hasMatch(note.source);
    }).toList();

    return notes.sublist(0, min(notes.length, 50));
  }

  Future<dynamic> graphQLRequest(query) async {
    if (DateTime.now().isAfter(_expirationDate)) {
      // TODO: refresh token here
      loginWithStorage();
    }
    try {
      var url = Path.join(apiUrl, 'graphql');
      var res = await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          "Authorization": "Bearer $_token",
        }),
        data: jsonEncode({
          "query": query,
        }),
      );
      return res;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<Note>> getAllNotes() async {
    var query =
        'query {  notes(query: {_isDeleted_ne: true}, sortBy: TIMESTAMP_DESC) {_id  title  content  source  timestamp}}';
    try {
      var box = await Hive.openBox('testBox');
      var noteMapList = box.get('notes');
      if (noteMapList == null) {
        // TODO: store notes individually by id into box
        var res = await graphQLRequest(query);
        noteMapList = jsonDecode(res.toString())['data']['notes'];
        await box.put('notes', noteMapList);
      }
      List<Note> notes = [];
      noteMapList.forEach((noteMap) {
        notes.add(Note.fromMap(noteMap));
      });
      return notes;
    } catch (e) {
      return [];
    }
  }

  Future<Note?> getNoteByTitle(title) async {
    var allNotes = await getAllNotes();
    Note? note = allNotes.firstWhereOrNull((note) {
      return note.title == title;
    });
    return note;
  }

  Future<bool> titleExists(id, title) async {
    var allNotes = await getAllNotes();
    Note? note = allNotes.firstWhereOrNull((note) {
      return note.title == title && note.id != id;
    });
    return note != null;
  }

  Future<List> getAllLinks() async {
    var allNotes = await getAllNotes();
    RegExp linkRegex = RegExp(Note.linkRegex, multiLine: true);
    var linkSet = Set();
    for (var note in allNotes) {
      linkSet.add(note.title);
      var matches = linkRegex.allMatches(note.content);
      for (var match in matches) {
        String link = match.group(0).toString();
        linkSet.add(link.substring(2, link.length - 2));
      }
    }
    linkSet.remove('');
    return linkSet.toList();
  }

  Future<bool> noteExists(Note note) async {
    var allNotes = await getAllNotes();
    Note? filteredNote = allNotes.firstWhereOrNull((n) {
      return n.id == note.id;
    });
    return filteredNote != null;
  }

  void upsertNote(Note note) async {
    bool isNoteInDb = await noteExists(note);
    if (isNoteInDb) {
      updateNote(note);
    } else {
      insertNote(note);
    }
  }

  void insertNote(Note note) {
    var query =
        'mutation { insertOneNote(data: {_id: "${note.id}", _partition: "$_userId",title: "${note.title}", content: "${note.content}", source: "${note.source}", timestamp: "${note.timestamp}", _isDeleted: ${note.isDeleted}}) { _id }}';
    graphQLRequest(query);
  }

  void updateNote(Note note) {
    var query =
        'mutation { updateOneNote(query: {_id: "${note.id}"}, set: {title: "${note.title}", content: "${note.content}", source: "${note.source}"}) { _id }}';
    graphQLRequest(query);
  }

  void deleteNote(Note note) {
    var query =
        'mutation { updateOneNote(query: {_id: "${note.id}"}, set: {_isDeleted: true}) { _id }}';
    graphQLRequest(query);
  }

  Future<bool> registerUser(String email, String password) async {
    // TODO: remove `flutter_mongodb_realm` dependency only used here.
    return await app.registerUser(email, password);
  }

  void logout() async {
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
    _token = null;
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
      _token = res.data['access_token'];
      _userId = res.data['user_id'];
      DateTime currentTime = DateTime.now();
      _expirationDate = currentTime.add(const Duration(minutes: 30));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Note>> getBacklinkNotes(Note note) async {
    if (note.title == '' || RegExp(Note.invalidChars).hasMatch(note.title)) {
      return [];
    }
    var allNotes = await getAllNotes();
    RegExp r = RegExp('\\[\\[${note.title}\\]\\]', multiLine: true);
    var notes = allNotes.where((note) {
      return r.hasMatch(note.content);
    }).toList();
    return notes;
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
