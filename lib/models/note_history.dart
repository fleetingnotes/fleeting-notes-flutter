import 'Note.dart';

class NoteHistory {
  NoteHistory({
    this.currNote,
    this.backNoteHistory = const [],
    this.forwardNoteHistory = const [],
  });
  Note? currNote;
  List<Note> backNoteHistory;
  List<Note> forwardNoteHistory;

  NoteHistory copy() {
    return NoteHistory(
      currNote: currNote,
      backNoteHistory: [...backNoteHistory],
      forwardNoteHistory: [...forwardNoteHistory],
    );
  }
}
