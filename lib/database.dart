import 'dart:math';

import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'models/Note.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';

enum SortOptions {
  dateASC,
  dateDESC,
  titleASC,
  titleDSC,
  contentASC,
  contentDESC,
  sourceASC,
  sourceDESC,
}

final Map sortMap = {
  SortOptions.dateASC: '',
};

class Database {
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: Find a way to move it out of here

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {Note.empty(): GlobalKey()};
  static const storage = FlutterSecureStorage();
  RealmDB realm = RealmDB();

  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  bool isLoggedIn() {
    return realm.isLoggedIn();
  }

  Future<List<Note>> getSearchNotes(queryRegex,
      {searchByTitle = true,
      searchByContent = true,
      searchBySource = true,
      forceSync = false}) async {
    String escapedQuery =
        queryRegex.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
      return '\\${match.group(0)}';
    });
    RegExp r = RegExp(escapedQuery, multiLine: true);
    var allNotes = await getAllNotes(forceSync: forceSync);
    var notes = allNotes.where((note) {
      return (searchByTitle && r.hasMatch(note.title)) ||
          (searchByContent && r.hasMatch(note.content)) ||
          (searchBySource && r.hasMatch(note.source));
    }).toList();

    return notes.sublist(0, min(notes.length, 50));
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    try {
      var box = await Hive.openBox(realm.userId);
      if ((box.isEmpty || forceSync) && isLoggedIn()) {
        List<Note> notes = await realm.getAllNotesRealm();
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        // box.clear(); // TODO: investigate why this causes bugs
        await box.putAll(noteIdMap);
      }
      List<Note> notes = getAllNotesLocal(box);
      notes.sort((Note n1, Note n2) => n2.timestamp.compareTo(n1.timestamp));
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
    var box = await Hive.openBox(realm.userId);
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
        bool isSuccess = await realm.insertNoteRealm(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(realm.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await realm.updateNoteRealm(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(realm.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await realm.deleteNoteRealm(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(realm.userId);
      box.delete(note.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() async {
    realm.logoutRealm();
    await storage.delete(key: 'email');
    await storage.delete(key: 'password');
  }

  Future<bool> loginWithStorage() async {
    String? email;
    String? password;
    try {
      email = await getEmail();
      password = await getPassword();
    } catch (e) {
      return false;
    }

    if (email == null || password == null) {
      return false;
    }
    bool validCredentials = await realm.loginRealm(email, password);
    return validCredentials;
  }

  Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }

  Future<String?> getPassword() async {
    return await storage.read(key: 'password');
  }

  Future<bool> register(String email, String password) {
    return realm.registerUserRealm(email, password);
  }

  Future<bool> login(String email, String password,
      {bool pushLocalNotes = false}) async {
    bool validCredentials = await realm.loginRealm(email, password);
    if (validCredentials) {
      await storage.write(key: 'email', value: email);
      await storage.write(key: 'password', value: password);
      if (pushLocalNotes) {
        var box = await Hive.openBox('local');
        List<Note> notes = getAllNotesLocal(box);
        if (notes.isNotEmpty) {
          await realm.updateNotesRealm(notes);
        }
      }
    }
    return validCredentials;
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
    var box = await Hive.openBox(realm.userId);
    box.watch().listen((event) {
      callback(event);
    });
  }

  void popAllRoutes() {
    noteHistory.clear();
    navigatorKey.currentState!.popUntil((route) => false);
  }
}
