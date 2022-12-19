import 'dart:async';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import '../../models/Note.dart';
import '../settings.dart';

class SyncManager {
  List<SyncTerface> allSyncs;
  final Settings settings;
  final Stream<NoteEvent> mainSyncStream;
  final void Function(NoteEvent) handleSyncFromExternal;
  final Future<Iterable<Note>> Function() getAllNotes;
  final List<StreamSubscription<NoteEvent>> streamSubs = [];
  SyncManager(
    this.allSyncs,
    this.mainSyncStream,
    this.handleSyncFromExternal,
    this.settings,
    this.getAllNotes,
  ) {
    streamSubs.add(mainSyncStream.listen(handleSyncFromMain));
    getAllNotes().then((notes) {
      for (var s in allSyncs) {
        streamSubs.add(s.noteStream.listen(handleSyncFromExternal));
        s.init(notes: notes);
      }
    });
  }

  void handleSyncFromMain(NoteEvent e) async {
    for (var s in allSyncs) {
      if (!s.canSync) continue;
      switch (e.status) {
        case NoteEventStatus.init:
          var notesToUpdate = await getNotesToUpdate(e.notes, s.getNotesByIds,
              shouldCreateNote: true);
          if (notesToUpdate.isEmpty) break;
          await s.upsertNotes(notesToUpdate);
          break;
        case NoteEventStatus.upsert:
          var notesToUpdate = await getNotesToUpdate(e.notes, s.getNotesByIds,
              shouldCreateNote: true);
          if (notesToUpdate.isEmpty) break;
          await s.upsertNotes(notesToUpdate);
          break;
        case NoteEventStatus.delete:
          await s.deleteNotes(e.notes.map((n) => n.id));
          break;
      }
    }
  }

  // prioritizes notes with greater modified time & only syncs notes already existing
  static Note? mergeIncomingNote(Note? currNote, Note incomingNote) {
    if (currNote == null) return incomingNote;
    bool isSimilarNote(Note n1, Note n2) {
      return n1.title == n2.title &&
          n1.content == n2.content &&
          n1.source == n2.source;
    }

    var localModified = DateTime.parse(currNote.modifiedAt);
    var externalModfiied = DateTime.parse(incomingNote.modifiedAt);
    if (externalModfiied.isAfter(localModified) &&
        !isSimilarNote(currNote, incomingNote)) {
      currNote.title = incomingNote.title;
      currNote.content = incomingNote.content;
      currNote.source = incomingNote.source;
      currNote.modifiedAt = incomingNote.modifiedAt;
      return currNote;
    }
    return null;
  }

  static Future<List<Note>> getNotesToUpdate(Iterable<Note> incomingNotes,
      Future<Iterable<Note?>> Function(Iterable<String> ids) getNotesByIds,
      {bool shouldCreateNote = false}) async {
    List<Note> notesToUpdate = [];

    // gets mapping of local notes
    Iterable<Note?> localNotes =
        await getNotesByIds(incomingNotes.map((n) => n.id));
    Map<String, Note> noteIdMapping = {};
    for (var n in localNotes) {
      if (n != null) noteIdMapping[n.id] = n;
    }

    for (var n in incomingNotes) {
      Note? localNote = noteIdMapping[n.id];
      if (localNote != null || shouldCreateNote) {
        var newLocalNote = mergeIncomingNote(localNote, n);
        if (newLocalNote != null) {
          notesToUpdate.add(newLocalNote);
        }
      }
    }
    return notesToUpdate;
  }
}
