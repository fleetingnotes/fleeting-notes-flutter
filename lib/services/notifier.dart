import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/Note.dart';

class NoteNotifier extends StateNotifier<List<Note>> {
  Database db;
  NoteNotifier(
    this.db,
  ) : super([Note.empty()]) {
    db.listenNoteChange((event) {
      if (event.status == NoteEventStatus.init) return;
      for (var note in event.notes) {
        db.getNoteById(note.id).then((retrievedNote) {
          if (retrievedNote == null || retrievedNote.isDeleted) {
            deleteNotes([note.id]);
          } else {
            updateNotes([retrievedNote]);
          }
        });
      }
    });
  }

  void addNote(Note note) {
    if (state.isEmpty || state.first.id != note.id) {
      state = [note, ...state];
    }
    updateNotes([note]);
  }

  void updateNotes(Iterable<Note> notes) {
    var noteMapping = {for (var note in notes) note.id: note};
    state = [
      for (final stateNote in state) noteMapping[stateNote.id] ?? stateNote
    ];
  }

  void deleteNotes(Iterable<String> noteIds) {
    var noteIdsSet = noteIds.toSet();
    state = [
      for (final note in state)
        if (!noteIdsSet.contains(note.id)) note
    ];
  }
}
