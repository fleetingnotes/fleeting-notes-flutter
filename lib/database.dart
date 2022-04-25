import 'dart:math';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'db/firebase.dart';
import 'models/Note.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/db/realm.dart';
import 'models/search_query.dart';
import 'package:firebase_remote_config_web/firebase_remote_config_web.dart';

class Database {
  Database({
    required this.firebase,
  }) {
    configRemoteConfig();
  }

  final FirebaseDB firebase;
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: Find a way to move it out of here

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {};
  static const storage = FlutterSecureStorage();
  RealmDB realm = RealmDB();

  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  final remoteConfig = FirebaseRemoteConfig.instance;

  bool isLoggedIn() {
    // Realm always has to be logged in
    // If "use_firebase" is false, short circuit and don't check firebase
    // If "use_firebase" is true, then must also be logged into firebase
    return realm.isLoggedIn() &&
        (!remoteConfig.getBool("use_firebase") || firebase.isLoggedIn());
  }

  Future<void> configRemoteConfig() async {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(seconds: 1),
    ));
    await remoteConfig.setDefaults(const {"use_firebase": false});
    await remoteConfig.fetchAndActivate();
  }

  Future<List<Note>> getSearchNotes(SearchQuery query,
      {forceSync = false}) async {
    String escapedQuery =
        query.queryRegex.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
      return '\\${match.group(0)}';
    });
    RegExp r = RegExp(escapedQuery, multiLine: true);
    var allNotes = await getAllNotes(forceSync: forceSync);
    var notes = allNotes.where((note) {
      return (query.searchByTitle && r.hasMatch(note.title)) ||
          (query.searchByContent && r.hasMatch(note.content)) ||
          (query.searchBySource && r.hasMatch(note.source));
    }).toList();
    notes.sort(sortMap[query.sortBy]);
    return notes.sublist(0, min(notes.length, 50));
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    try {
      var box = await Hive.openBox(realm.userId);
      if ((box.isEmpty || forceSync) && isLoggedIn()) {
        List<Note> notes = remoteConfig.getBool("use_firebase")
            ? await firebase.getAllNotes()
            : await realm.getAllNotes();
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        // box.clear(); // TODO: investigate why this causes bugs
        await box.putAll(noteIdMap);
      }
      List<Note> notes = getAllNotesLocal(box);
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
    Note? filteredNote = await getNoteById(note.id);
    return filteredNote != null;
  }

  Future<Note?> getNoteById(String id) async {
    var box = await Hive.openBox(realm.userId);
    return box.get(id);
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
      if (realm.isLoggedIn()) {
        bool isSuccess = await realm.insertNote(note);
        if (!isSuccess) return false;
      }
      if (firebase.isLoggedIn()) firebase.insertNote(note);
      var box = await Hive.openBox(realm.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      if (realm.isLoggedIn()) {
        bool isSuccess = await realm.updateNote(note);
        if (!isSuccess) return false;
      }
      if (firebase.isLoggedIn()) firebase.updateNote(note);
      var box = await Hive.openBox(realm.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotes(List<Note> notes) async {
    try {
      if (realm.isLoggedIn()) {
        bool isSuccess = await realm.updateNotes(notes);
        if (!isSuccess) return false;
      }
      if (firebase.isLoggedIn()) firebase.updateNotes(notes);
      var box = await Hive.openBox(realm.userId);
      Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
      await box.putAll(noteIdMap);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    try {
      if (realm.isLoggedIn()) {
        bool isSuccess = await realm.deleteNote(note);
        if (!isSuccess) return false;
      }
      if (firebase.isLoggedIn()) firebase.deleteNote(note);
      var box = await Hive.openBox(realm.userId);
      box.delete(note.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() async {
    firebase.logout();
    realm.logout();
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
    bool validCredentials = await login(email, password);
    return validCredentials;
  }

  Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }

  Future<String?> getPassword() async {
    return await storage.read(key: 'password');
  }

  Future<bool> register(String email, String password) async {
    if (!await firebase.register(email, password)) return false;
    bool isRegistered = await realm.register(email, password);
    return isRegistered;
  }

  Future<bool> login(String email, String password,
      {bool pushLocalNotes = false}) async {
    bool validCredentials = await realm.login(email, password);
    if (validCredentials) {
      await storage.write(key: 'email', value: email);
      await storage.write(key: 'password', value: password);
      if (pushLocalNotes) {
        var box = await Hive.openBox('local');
        List<Note> notes = getAllNotesLocal(box);
        if (notes.isNotEmpty) {
          await realm.updateNotes(notes);
        }
      }
      if (!firebase.isLoggedIn()) {
        migrateToFirebase(email, password);
      }
    }
    return validCredentials;
  }

  Future<bool> migrateToFirebase(String email, String password) async {
    await firebase.register(email, password);
    if (!await firebase.login(email, password)) {
      await firebase.analytics.logEvent(
          name: 'firebase_migration', parameters: {'is_success': false});
      return false;
    }
    List<Note> notes = await realm.getAllNotes();
    await firebase.updateNotes(notes);
    await firebase.analytics
        .logEvent(name: 'firebase_migration', parameters: {'is_success': true});
    return true;
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
  void navigateToNote(Note note, {bool isShared = false}) {
    GlobalKey noteKey = GlobalKey();
    noteHistory[note] = noteKey;
    navigatorKey.currentState!.push(PageRouteBuilder(
      pageBuilder: (context, _, __) =>
          NoteEditor(key: noteKey, db: this, note: note, isShared: isShared),
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
