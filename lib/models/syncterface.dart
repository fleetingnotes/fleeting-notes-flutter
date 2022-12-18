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
  Future<void> deleteNotes(Iterable<String> ids);
  // pushes notes to sync and initializes any listeners
  Future<void> init({Iterable<Note> notes = const Iterable.empty()});
  // retrieves notes given note ids
  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids);
  // can a sync be performed
  bool get canSync;
  // whenever notes are updated / deleted / read a NoteEvent is sent
  Stream<NoteEvent> get noteStream;
}
