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
import 'package:http/http.dart' as http;
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
  http.Client httpClient = http.Client();
  Database({
    required this.supabase,
    required this.localFileSync,
    required this.settings,
  }) {
    syncManager = SyncManager(
      [supabase, localFileSync],
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
      {forceSync = false, bool filterDeletedNotes = false}) async {
    RegExp r = getQueryRegex(query.query);
    bool noteValid(Note note) =>
        note.isDeleted == filterDeletedNotes &&
        ((query.searchByTitle && r.hasMatch(note.title)) ||
            (query.searchByContent && r.hasMatch(note.content)) ||
            (query.searchBySource &&
                (r.hasMatch(note.source) ||
                    r.hasMatch(note.sourceTitle ?? ''))));
    var allNotes = await getAllNotes(
        forceSync: forceSync, filterDeletedNotes: filterDeletedNotes);
    var notes = allNotes.where(noteValid).toList();
    notes.sort(sortMap[query.sortBy]);
    return notes.sublist(0, min(notes.length, query.limit ?? notes.length));
  }

  Future<List<Note>> getAllNotes(
      {forceSync = false, bool? filterDeletedNotes = false}) async {
    var box = await getBox();
    try {
      if ((box.isEmpty || forceSync) && loggedIn) {
        DateTime? lastSyncTime = settings.get('last-sync-time');
        List<Note>? tempNotes;
        List<Note> notes = [];
        int start = 0, end = 1000;
        while (tempNotes == null || tempNotes.length == 1000) {
          tempNotes = await supabase.getAllNotes(
              partition: shareUserId,
              modifiedAfter: lastSyncTime,
              start: start,
              end: end,
              filterDeletedNotes: filterDeletedNotes);
          start += 1000;
          end += 1000;
          notes.addAll(tempNotes);
        }
        settings.set('last-sync-time', DateTime.now());
        Map<String, Note> noteIdMap = {for (var note in notes) note.id: note};
        await box.putAll(noteIdMap);
        noteChangeController.add(NoteEvent(notes, NoteEventStatus.init));
      }
    } catch (e) {
      // catch errors with getAllNotes
    }
    List<Note> notes =
        getAllNotesLocal(box, filterDeletedNotes: filterDeletedNotes);
    return notes;
  }

  List<Note> getAllNotesLocal(Box box, {bool? filterDeletedNotes = false}) {
    List<Note> notes = [];
    for (var note in box.values) {
      if (note.runtimeType == Note && note.isDeleted == filterDeletedNotes) {
        notes.add(note);
      }
    }
    return notes;
  }

  Future<Note?> getNoteByTitle(String title) async {
    // When updating this function ensure that latest note gets returned
    // this is important for when user creates new note with same title
    if (title.isEmpty) return null;
    var allNotes = await getAllNotes();
    Note? note = allNotes.lastWhereOrNull((note) {
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

  Future<List<String>> getAllItems(RegExp re, int group,
      {bool addTitle = false}) async {
    var allNotes = await getAllNotes();
    var linkSet = <String>{};
    for (var note in allNotes) {
      if (addTitle) {
        linkSet.add(note.title);
      }
      var matches = re.allMatches(note.content);
      for (var match in matches) {
        String? item = match.group(group);
        if (item != null) {
          linkSet.add(item);
        }
      }
    }
    linkSet.remove('');
    return linkSet.toList();
  }

  Future<List<String>> getAllLinks() async {
    return getAllItems(RegExp(Note.linkRegex, multiLine: true), 1,
        addTitle: true);
  }

  Future<List<String>> getAllTags() async {
    return getAllItems(RegExp(Note.tagRegex, multiLine: true), 2);
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

  Future<bool> restoreNotes(List<Note> notes) async {
    try {
      var box = await getBox();
      Map<String, Note> noteIdMap = {};
      for (var note in notes) {
        Note boxNote = box.get(note.id, defaultValue: note);
        boxNote.isDeleted = false;
        noteIdMap[note.id] = boxNote;
      }
      await box.putAll(noteIdMap);
      noteChangeController.add(NoteEvent(notes, NoteEventStatus.upsert));
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

  // TODO: remove this because notes should be already intialized in supabase.init()
  // but i'll need to test so that it maintains same behaviour
  Future<void> initNotes() async {
    var notes = await getAllNotes(forceSync: true);
    noteChangeController.add(NoteEvent(notes, NoteEventStatus.init));
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
        List<Note> notesToUpdate = await SyncManager.getNotesToUpdate(
            e.notes, getNotesByIds,
            shouldCreateNote: true);
        if (notesToUpdate.isEmpty) break;
        upsertNotes(notesToUpdate);
        break;
      case NoteEventStatus.delete:
        List<Note> notesToUpdate =
            await SyncManager.getNotesToUpdate(e.notes, getNotesByIds);
        if (notesToUpdate.isEmpty) break;
        deleteNotes(notesToUpdate);
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

    // upload file & return url
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
    if (!loggedIn) {
      settings.delete('last-sync-time');
    }
    final search = ref.read(searchProvider.notifier);
    await initNotes();
    shareUserId = null;
    search.updateSearch(null);
  }
}
