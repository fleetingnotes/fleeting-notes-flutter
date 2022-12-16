import 'Note.dart';

enum NoteEventStatus { init, upsert, delete }

class NoteEvent {
  Iterable<Note> notes;
  NoteEventStatus status;
  NoteEvent(
    this.notes,
    this.status,
  );
}

abstract class SyncTerface {
  // upserts notes passed in
  Future<void> upsertNotes(Iterable<Note> notes);
  // deletes notes passed in
  Future<void> deleteNotes(Iterable<Note> notes);
  // pushes notes to sync and initializes any listeners
  Future<void> init({Iterable<Note> notes = const Iterable.empty()});
  // retrieves notes given note ids
  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids);
  // can a sync be performed
  bool get canSync;
  // whenever notes are updated / deleted / read a NoteEvent is sent
  Stream<NoteEvent> get noteStream;
}

// prioritizes notes with greater modified time & only syncs notes already existing
Note? mergeIncomingNote(Note? currNote, Note incomingNote) {
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

Future<List<Note>> getNotesToUpdate(Iterable<Note> incomingNotes,
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
