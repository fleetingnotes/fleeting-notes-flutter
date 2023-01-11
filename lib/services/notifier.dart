import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/Note.dart';

class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier() : super([Note.empty()]);

  void addNote(Note note) {
    if (state.first.id != note.id) {
      state = [note, ...state];
    }
    updateNote(note);
  }

  void updateNote(Note note) {
    state = [
      for (final stateNote in state)
        if (note.id == stateNote.id) note else stateNote,
    ];
  }

  void removeNote(String noteId) {
    state = [
      for (final note in state)
        if (note.id != noteId) note,
    ];
  }
}
