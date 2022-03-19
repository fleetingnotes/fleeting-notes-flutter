import 'dart:html';
import 'dart:io';
import 'dart:math';

import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as Path;

class RealmDB {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {Note.empty(): GlobalKey()};
  static const storage = FlutterSecureStorage();
  late String _userId;
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
      return jsonDecode(res.toString());
    } catch (e) {
      return null;
    }
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    var query =
        'query {  notes(query: {_isDeleted_ne: true}, sortBy: TIMESTAMP_DESC) {_id  title  content  source  timestamp}}';
    try {
      var box = await Hive.openBox(_userId);
      if (box.isEmpty || forceSync) {
        var res = await graphQLRequest(query);
        var noteMapList = res['data']['notes'];
        Map<String, Note> noteIdMap = {
          for (var note in noteMapList) note['_id']: Note.fromMap(note)
        };
        // box.clear(); // TODO: investigate why this causes bugs
        await box.putAll(noteIdMap);
      }
      List<Note> notes = [];
      for (var note in box.values) {
        notes.add(note as Note);
      }
      notes.sort((n1, n2) => n2.timestamp.compareTo(n1.timestamp));
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

  Future<bool> insertNote(Note note) async {
    try {
      var query =
          'mutation { insertOneNote(data: {_id: "${note.id}", _partition: "$_userId",title: "${note.title}", content: "${note.content}", source: "${note.source}", timestamp: "${note.timestamp}", _isDeleted: ${note.isDeleted}}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      Note insertedNote = Note.fromMap(res["data"]["insertOneNote"]);
      var box = await Hive.openBox(_userId);
      box.put(insertedNote.id, insertedNote);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      var query =
          'mutation { updateOneNote(query: {_id: "${note.id}"}, set: {title: "${note.title}", content: "${note.content}", source: "${note.source}"}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      Note updatedNote = Note.fromMap(res["data"]["updateOneNote"]);
      var box = await Hive.openBox(_userId);
      box.put(updatedNote.id, updatedNote);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    try {
      var query =
          'mutation { updateOneNote(query: {_id: "${note.id}"}, set: {_isDeleted: true}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      Note deletedNote = Note.fromMap(res["data"]["updateOneNote"]);
      var box = await Hive.openBox(_userId);
      box.delete(deletedNote.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerUser(String email, String password) async {
    var url = Path.join(apiUrl, 'auth/providers/local-userpass/register');
    try {
      await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
        }),
        data: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() async {
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
    searchKey = GlobalKey();
    noteHistory = {Note.empty(): GlobalKey()};
    _token = null;
  }

  Future<bool> loginWithStorage() async {
    String? email;
    String? password;
    try {
      email = await storage.read(key: 'email');
      password = await storage.read(key: 'password');
    } catch (e) {
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
        pageBuilder: (context, _, __) => SearchScreen(db: this),
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
    GlobalKey noteKey = GlobalKey();
    noteHistory[note] = noteKey;
    navigatorKey.currentState!.push(PageRouteBuilder(
      pageBuilder: (context, _, __) =>
          NoteScreen(key: noteKey, db: this, note: note),
      transitionsBuilder: _transitionBuilder,
    ));
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void listenNoteChange(Function callback) async {
    var box = await Hive.openBox(_userId);
    box.watch().listen((event) {
      callback(event);
    });
  }

  void popAllRoutes() {
    noteHistory.clear();
    navigatorKey.currentState!.popUntil((route) => false);
  }
}
