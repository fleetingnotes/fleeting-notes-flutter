import 'dart:math';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'db/firebase.dart';
import 'models/Note.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'models/search_query.dart';

class Database {
  Database({
    required this.firebase,
  }) : super();

  final FirebaseDB firebase;
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: Find a way to move it out of here

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {};

  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  bool isLoggedIn() {
    return firebase.isLoggedIn();
  }

  Future<List<Note>> getSearchNotes(SearchQuery query,
      {forceSync = false}) async {
    RegExp r = getQueryRegex(query.query);
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
      var box = await Hive.openBox(firebase.userId);
      if ((((box.isEmpty || forceSync) && isLoggedIn()) ||
          firebase.isSharedNotes)) {
        List<Note> notes =
            await firebase.getAllNotes(isShared: firebase.isSharedNotes);
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

  Future<Note?> getNoteByTitle(String title) async {
    if (title.isEmpty) return null;
    var allNotes = await getAllNotes();
    Note? note = allNotes.firstWhereOrNull((note) {
      return note.title == title;
    });
    return note;
  }

  Future<Note?> getNote(id) async {
    var box = await Hive.openBox(firebase.userId);
    return box.get(id) as Note?;
  }

  Future<bool> titleExists(id, title) async {
    var allNotes = await getAllNotes();
    Note? note = allNotes.firstWhereOrNull((note) {
      return note.title == title && note.id != id;
    });
    return note != null;
  }

  Future<List<String>> getAllLinks() async {
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
    var box = await Hive.openBox(firebase.userId);
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
      if (firebase.isLoggedIn()) {
        bool isSuccess = await firebase.insertNote(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(firebase.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNote(Note note) async {
    try {
      if (firebase.isLoggedIn()) {
        bool isSuccess = await firebase.updateNote(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(firebase.userId);
      box.put(note.id, note);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotes(List<Note> notes) async {
    try {
      if (firebase.isLoggedIn()) {
        bool isSuccess = await firebase.updateNotes(notes);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(firebase.userId);
      Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
      await box.putAll(noteIdMap);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(Note note) async {
    try {
      if (firebase.isLoggedIn()) {
        bool isSuccess = await firebase.deleteNote(note);
        if (!isSuccess) return false;
      }
      var box = await Hive.openBox(firebase.userId);
      box.delete(note.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (firebase.userId != 'local') {
      var box = await Hive.openBox(firebase.userId);
      box.clear();
    }
    await firebase.logout();
  }

  Future<bool> register(String email, String password) async {
    return await firebase.register(email, password);
  }

  Future<bool> login(String email, String password) async {
    if (!firebase.isLoggedIn()) {
      bool isSuccess = await firebase.login(email, password);
      if (!isSuccess) return false;
    }
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

  Note? getUnsavedNote() {
    return Hive.box('settings').get('unsaved-note');
  }

  void setUnsavedNote(Note note) {
    Hive.box('settings').put('unsaved-note', note);
  }

  void clearUnsavedNote() {
    Hive.box('settings').delete('unsaved-note');
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  Future<StreamSubscription> listenNoteChange(Function callback) async {
    var box = await Hive.openBox(firebase.userId);
    return box.watch().listen((event) {
      callback(event);
    });
  }

  void popAllRoutes() {
    if (navigatorKey.currentState != null) {
      noteHistory.clear();
      navigatorKey.currentState?.popUntil((route) => false);
    }
  }

  Future<void> setFillSource(bool autoFillEnabled) async {
    await Hive.box('settings').put('auto-fill-source', autoFillEnabled);
  }

  bool fillSource() {
    return Hive.box('settings').get('auto-fill-source') ?? false;
  }

  bool? getAnalyticsEnabled() {
    return Hive.box('settings').get('analytics-enabled');
  }

  void setAnalyticsEnabled(enabled) {
    Hive.box('settings').put('analytics-enabled', enabled);
    firebase.setAnalytics(enabled);
  }

  void refreshApp() {
    firebase.userId = firebase.currUser?.uid ?? 'local';
    popAllRoutes();
    searchKey = GlobalKey();
    noteHistory = {Note.empty(): GlobalKey()};
  }
}
