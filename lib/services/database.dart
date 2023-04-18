import 'dart:convert';
import 'dart:math';
import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';
import 'package:fleeting_notes_flutter/services/sync/sync_manager.dart';
import 'package:fleeting_notes_flutter/services/text_similarity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
      [localFileSync, supabase],
      noteChangeController.stream,
      handleSyncFromExternal,
      settings,
      () async => getAllNotesLocal(await getBox()),
    );
  }
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController<NoteEvent> noteChangeController =
      StreamController.broadcast();
  String? shareUserId;
  Box? _currBox;
  Future<Box> getBox() async {
    var boxName = shareUserId ?? supabase.userId ?? 'local';
    if (_currBox?.name != boxName) {
      _currBox = await Hive.openBox(boxName);
    }
    return _currBox as Box;
  }

  bool get loggedIn => supabase.currUser != null;

  Future<List<Note>> getSearchNotes(SearchQuery query,
      {forceSync = false}) async {
    RegExp r = getQueryRegex(query.query);
    var allNotes = await getAllNotes(forceSync: forceSync);
    var notes = allNotes.where((note) {
      return (query.searchByTitle && r.hasMatch(note.title)) ||
          (query.searchByContent && r.hasMatch(note.content)) ||
          (query.searchBySource &&
              (r.hasMatch(note.source) || r.hasMatch(note.sourceTitle ?? '')));
    }).toList();
    notes.sort(sortMap[query.sortBy]);
    return notes.sublist(0, min(notes.length, query.limit ?? notes.length));
  }

  Future<List<Note>> getAllNotes({forceSync = false}) async {
    var box = await getBox();
    try {
      if ((box.isEmpty || forceSync) && loggedIn) {
        List<Note> notes = await supabase.getAllNotes(partition: shareUserId);
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        await box.clear();
        await box.putAll(noteIdMap);
        noteChangeController.add(NoteEvent(notes, NoteEventStatus.init));
      }
    } catch (e) {
      // catch errors with getAllNotes
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
    print(box.get(ids.first).modifiedAt);
    return ids.map((id) => box.get(id));
  }

  Future<bool> upsertNotes(List<Note> notes,
      {bool setModifiedAt = false}) async {
    try {
      if (loggedIn) {
        // await supabase.upsertNotes(notes);
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
      if (loggedIn) {
        // await supabase.deleteNotes(notes.map((n) => n.id));
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

  Future<User?> login(String email, String password) async {
    return await supabase.login(email, password);
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

  Future<void> initNotes() async {
    var notes = await getAllNotes(forceSync: true);
    noteChangeController.add(NoteEvent(notes, NoteEventStatus.init));
  }

  void handleSyncFromExternal(NoteEvent e) async {
    print('handleSyncFromExternal');
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
        print('$notesToUpdate and ${e.notes}');
        if (notesToUpdate.isEmpty) break;
        upsertNotes(notesToUpdate);
        break;
      case NoteEventStatus.delete:
        deleteNotes(e.notes.toList());
        break;
    }
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

  Future<String> uploadAttachment(
      {String? filename, Uint8List? fileBytes}) async {
    // get filename with extension
    filename = filename ?? const Uuid().v4();
    final mimeType = lookupMimeType(filename, headerBytes: fileBytes);
    String ext = (mimeType != null) ? extensionFromMime(mimeType) : "";
    if (filename.split('.').length == 1 && ext.isNotEmpty) {
      filename = "$filename.$ext";
    }

    // upload file & return note
    return await supabase.addAttachment(filename, fileBytes);
  }

  Future<Note?> addAttachmentToNewNote(
      {String? filename, Uint8List? fileBytes}) async {
    Note newNote = Note.empty();
    // upload file & return note
    String sourceUrl =
        await uploadAttachment(filename: newNote.id, fileBytes: fileBytes);
    final mimeType = lookupMimeType(newNote.id, headerBytes: fileBytes);
    String ext = (mimeType != null) ? extensionFromMime(mimeType) : "";
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

  Future<void> refreshApp(WidgetRef ref) async {
    final search = ref.read(searchProvider.notifier);
    await initNotes();
    shareUserId = null;
    search.updateSearch(null);
  }
}
