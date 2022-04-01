import 'dart:io';
import 'dart:math';

import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'models/Note.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';
// ignore: library_prefixes
import 'package:path/path.dart' as Path;

class RealmDB {
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: Find a way to move it out of here

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {Note.empty(): GlobalKey()};
  static const storage = FlutterSecureStorage();
  String _userId = 'local';
  String? _token;
  DateTime _expirationDate = DateTime.now();
  String apiUrl =
      'https://realm.mongodb.com/api/client/v2.0/app/fleeting-notes-knojs/';
  Dio dio = Dio();

  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  bool isLoggedIn() {
    return _userId != 'local';
  }

  Future<List<Note>> getSearchNotes(queryRegex, {forceSync = false}) async {
    String escapedQuery =
        queryRegex.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
      return '\\${match.group(0)}';
    });
    RegExp r = RegExp(escapedQuery, multiLine: true);
    var allNotes = await getAllNotes(forceSync: forceSync);
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
      await loginWithStorage();
    }
    try {
      var url = Path.join(apiUrl, 'graphql');
      var res = await Dio().post(
        url,
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          "Authorization": "Bearer $_token",
        }),
        data: {
          "query": query,
        },
      );
      return jsonDecode(res.toString());
    } catch (e) {
      return null;
    }
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    try {
      var box = await Hive.openBox(_userId);
      if ((box.isEmpty || forceSync) && isLoggedIn()) {
        List<Note> notes = await getAllNotesRealm();
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        // box.clear(); // TODO: investigate why this causes bugs
        await box.putAll(noteIdMap);
      }
      List<Note> notes = getAllNotesLocal(box);
      notes.sort((n1, n2) => n2.timestamp.compareTo(n1.timestamp));
      return notes;
    } catch (e) {
      return [];
    }
  }

  Future<List<Note>> getAllNotesRealm() async {
    var query =
        'query {  notes(query: {_isDeleted_ne: true}, sortBy: TIMESTAMP_DESC) {_id  title  content  source  timestamp}}';
    try {
      var res = await graphQLRequest(query);
      var noteMapList = res['data']['notes'];
      List<Note> notes = [for (var note in noteMapList) Note.fromMap(note)];
      return notes;
    } catch (e) {
      return [];
    }
  }

  List<Note> getAllNotesLocal(box) {
    List<Note> notes = [];
    for (var note in box.values) {
      notes.add(note as Note);
    }
    return notes;
  }

  Future<Note?> getNoteByTitle(title) async {
    var allNotes = await getAllNotes();
    Note? note = allNotes.firstWhereOrNull((note) {
      return note.title == title;
    });
    return note;
  }

  Future<Note?> getNote(id) async {
    var box = await Hive.openBox(_userId);
    return box.get(id) as Note?;
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
    var linkSet = <String>{};
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

  Future<bool> upsertNote(Note note) async {
    bool isNoteInDb = await noteExists(note);
    if (isNoteInDb) {
      return await updateNote(note);
    } else {
      return await insertNote(note);
    }
  }

  Future<bool> insertNote(Note note) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await insertNoteRealm(note);
        if (!isSuccess) return false;
      }
      await insertNoteRealm(note);
      var box = await Hive.openBox(_userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> insertNoteRealm(Note note) async {
    try {
      Note encodedNote = Note.encodeNote(note);
      var query =
          'mutation { insertOneNote(data: {_id: ${encodedNote.id}, _partition: ${jsonEncode(_userId)},title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}, timestamp: ${encodedNote.timestamp}, _isDeleted: ${encodedNote.isDeleted}}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = Note.fromMap(res["data"]["insertOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await updateNoteRealm(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(_userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNoteRealm(Note note) async {
    try {
      Note encodedNote = Note.encodeNote(note);
      var query =
          'mutation { updateOneNote(query: {_id: ${encodedNote.id}}, set: {title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = Note.fromMap(res["data"]["updateOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotesRealm(List<Note> notes) async {
    try {
      List queryList = notes.map((note) {
        Note encodedNote = Note.encodeNote(note);
        String noteQuery =
            '{_id: ${encodedNote.id}, _partition: ${jsonEncode(_userId)},title: ${encodedNote.title}, content: ${encodedNote.content}, source: ${encodedNote.source}, timestamp: ${encodedNote.timestamp}, _isDeleted: ${encodedNote.isDeleted}}';
        return noteQuery;
      }).toList();
      String query =
          'mutation { insertManyNotes(data: ${queryList.toString()}) { insertedIds } }';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await deleteNoteRealm(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(_userId);
      box.delete(note.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNoteRealm(Note note) async {
    try {
      Note encodedNote = Note.encodeNote(note);
      var query =
          'mutation { updateOneNote(query: {_id: ${encodedNote.id}}, set: {_isDeleted: true}) {_id  title  content  source  timestamp}}';
      var res = await graphQLRequest(query);
      if (res['data'] == null) return false;
      note = Note.fromMap(res["data"]["updateOneNote"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerUserRealm(String email, String password) async {
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
    logoutRealm();
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
  }

  void logoutRealm() {
    _userId = 'local';
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
    bool validCredentials = await loginRealm(email, password);
    return validCredentials;
  }

  Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }

  Future<bool> login(String email, String password,
      {bool pushLocalNotes = false}) async {
    await storage.write(key: 'email', value: email);
    await storage.write(key: 'password', value: password);
    bool validCredentials = await loginRealm(email, password);
    if (validCredentials && pushLocalNotes) {
      var box = await Hive.openBox('local');
      List<Note> notes = getAllNotesLocal(box);
      if (notes.isNotEmpty) {
        await updateNotesRealm(notes);
      }
    }
    return validCredentials;
  }

  Future<bool> loginRealm(String email, String password) async {
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

  // TODO: Move this out of db
  void navigateToSearch(String query) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => SearchScreen(db: this),
        transitionsBuilder: _transitionBuilder,
      ),
    );
  }

  // TODO: Move this out of db
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

  // TODO: Move this out of db
  void navigateToNote(Note note) {
    GlobalKey noteKey = GlobalKey();
    noteHistory[note] = noteKey;
    navigatorKey.currentState!.push(PageRouteBuilder(
      pageBuilder: (context, _, __) =>
          NoteEditor(key: noteKey, db: this, note: note),
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
