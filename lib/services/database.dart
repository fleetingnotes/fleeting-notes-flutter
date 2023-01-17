import 'dart:convert';
import 'dart:math';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';
import 'package:fleeting_notes_flutter/services/sync/sync_manager.dart';
import 'package:fleeting_notes_flutter/services/text_similarity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../models/syncterface.dart';
import 'settings.dart';
import '../models/Note.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import '../models/search_query.dart';
import 'supabase.dart';

class Database {
  final SupabaseDB supabase;
  final LocalFileSync localFileSync;
  final Settings settings;
  final TextSimilarity textSimilarity = TextSimilarity();
  SyncManager? syncManager;
  BrowserExtension be = BrowserExtension();
  Database({
    required this.supabase,
    required this.localFileSync,
    required this.settings,
  }) {
    syncManager = SyncManager(
      [localFileSync],
      noteChangeController.stream,
      handleSyncFromExternal,
      settings,
      () async => getAllNotesLocal(await getBox()),
    );
  }
  GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(); // TODO: Find a way to move it out of here

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey searchKey = GlobalKey();
  Map<Note, GlobalKey> noteHistory = {};
  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  StreamController<NoteEvent> noteChangeController =
      StreamController.broadcast();
  String? shareUserId;
  Box? _currBox;
  bool get isSharedNotes =>
      shareUserId != null &&
      !(shareUserId == supabase.userId || shareUserId == supabase.currUser?.id);
  Future<Box> getBox() async {
    var boxName = shareUserId ?? supabase.userId ?? 'local';
    if (_currBox?.name != boxName) {
      _currBox = await Hive.openBox(boxName);
    }
    return _currBox as Box;
  }

  bool isLoggedIn() {
    return supabase.currUser != null;
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
    return notes.sublist(0, min(notes.length, query.limit));
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    var box = await getBox();
    try {
      if ((box.isEmpty || forceSync) && (isLoggedIn() || isSharedNotes)) {
        List<Note> notes = await supabase.getAllNotes(partition: shareUserId);
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        await box.clear();
        await box.putAll(noteIdMap);
        noteChangeController.add(NoteEvent(notes, NoteEventStatus.init));
      }
    } catch (e, stack) {
      Sentry.captureException(e, stackTrace: stack);
    }
    List<Note> notes = getAllNotesLocal(box);
    return notes;
  }

  List<Note> getAllNotesLocal(Box box) {
    List<Note> notes = [];
    for (var note in box.values.cast<Note>()) {
      if (!note.isDeleted) {
        notes.add(note);
      }
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

  Future<Note?> getNote(String id) async {
    var box = await getBox();
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
        String? link = match.group(1);
        if (link != null) {
          linkSet.add(link);
        }
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
    var box = await getBox();
    return box.get(id);
  }

  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids) async {
    var box = await getBox();
    return ids.map((id) => box.get(id));
  }

  Future<bool> upsertNotes(List<Note> notes,
      {bool setModifiedAt = false}) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await supabase.upsertNotes(notes);
        if (!isSuccess) return false;
      }
      var box = await getBox();
      Map<String, Note> noteIdMap = {};
      for (var note in notes) {
        if (setModifiedAt) {
          note.modifiedAt = DateTime.now().toUtc().toIso8601String();
        }
        note.isDeleted = false;
        noteIdMap[note.id] = note;
      }
      await box.putAll(noteIdMap);
      noteChangeController.add(NoteEvent(notes, NoteEventStatus.upsert));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotes(List<Note> notes) async {
    try {
      if (isLoggedIn()) {
        bool isSuccess = await supabase.deleteNotes(notes);
        if (!isSuccess) return false;
      }
      var box = await getBox();
      Map<String, Note> noteIdMap = {};
      for (var note in notes) {
        Note boxNote = box.get(note.id, defaultValue: note);
        boxNote.isDeleted = true;
        noteIdMap[note.id] = boxNote;
      }
      await box.putAll(noteIdMap);
      noteChangeController.add(NoteEvent(notes, NoteEventStatus.delete));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (supabase.userId != 'local') {
      var box = await getBox();
      box.clear();
    }
    await supabase.logout();
  }

  Future<void> register(String email, String password) async {
    await supabase.register(email, password);
  }

  Future<void> login(String email, String password) async {
    await supabase.login(email, password);
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

  void handleSyncFromExternal(NoteEvent e) async {
    switch (e.status) {
      case NoteEventStatus.init:
        List<Note> notesToUpdate =
            await SyncManager.getNotesToUpdate(e.notes, getNotesByIds);
        if (notesToUpdate.isEmpty) break;
        upsertNotes(notesToUpdate);
        break;
      case NoteEventStatus.upsert:
        List<Note> notesToUpdate =
            await SyncManager.getNotesToUpdate(e.notes, getNotesByIds);
        if (notesToUpdate.isEmpty) break;
        upsertNotes(notesToUpdate);
        break;
      case NoteEventStatus.delete:
        deleteNotes(e.notes.toList());
        break;
    }
  }

  // TODO: Move this out of db
  void navigateToSearch(String query) {
    navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => const SearchScreen(),
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
    navigatorKey.currentState?.push(PageRouteBuilder(
      pageBuilder: (context, _, __) =>
          NoteEditor(key: noteKey, note: note, isShared: isShared),
      transitionsBuilder: _transitionBuilder,
    ));
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }

  Future<StreamSubscription> listenNoteChange(
      Function(NoteEvent) callback) async {
    return noteChangeController.stream.listen((event) {
      callback(event);
    });
  }

  void popAllRoutes() {
    if (navigatorKey.currentState != null) {
      noteHistory.clear();
      navigatorKey.currentState?.popUntil((route) => false);
    }
  }

  bool canPop() {
    var nState = navigatorKey.currentState;
    if (nState != null) {
      return nState.canPop();
    }
    return false;
  }

  Future<void> setAnalyticsEnabled(enabled) async {
    await settings.set('analytics-enabled', enabled);
  }

  Future<void> setInitialNotes() async {
    List remoteConfigInitNotes = jsonDecode(settings.get('initial-notes'));
    List<Note> initNotes = remoteConfigInitNotes
        .map((note) => Note.empty(
              title: note['title'],
              content: note['content'],
              source: note['source'],
            ))
        .toList();
    await upsertNotes(initNotes);
  }

  Future<Note?> addAttachmentToNewNote(
      {String? filename, Uint8List? fileBytes}) async {
    Note newNote = Note.empty();

    // get filename with extension
    filename = filename ?? newNote.id;
    final mimeType = lookupMimeType(filename, headerBytes: fileBytes);
    String ext = (mimeType != null) ? extensionFromMime(mimeType) : "";
    if (filename.split('.').length == 1 && ext.isNotEmpty) {
      filename = "$filename.$ext";
    }

    // upload file & return note
    String sourceUrl = await supabase.addAttachment(filename, fileBytes);
    String dateInNum = DateTime.now().toString().replaceAll(RegExp(r'\D'), '');
    newNote.source = sourceUrl;
    newNote.title = "file-$dateInNum";
    newNote.title += (ext.isEmpty) ? "" : ".$ext";
    if (await upsertNotes([newNote])) {
      return newNote;
    }
    return null;
  }

  void insertTextAtSelection(TextEditingController controller, String text) {
    if (text.isEmpty) return;
    var currSelection = controller.selection;
    int start = controller.text.length;
    int end = start;
    if (currSelection.start >= 0 && currSelection.end >= 0) {
      start = currSelection.start;
      end = currSelection.end;
    }
    controller.text = controller.text.replaceRange(start, end, text);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: start + text.length));
  }

  void refreshApp() {
    shareUserId = null;
    popAllRoutes();
    searchKey = GlobalKey();
    noteHistory = {Note.empty(): GlobalKey()};
    navigateToSearch('');
  }
}
