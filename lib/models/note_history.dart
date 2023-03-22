import 'Note.dart';

class NoteHistory {
  NoteHistory({
    this.currNote,
    this.backNoteHistory = const [],
    this.forwardNoteHistory = const [],
  });

  bool get isEmpty =>
      currNote == null && backNoteHistory.isEmpty && forwardNoteHistory.isEmpty;
  bool get isHistoryEmpty =>
      backNoteHistory.isEmpty && forwardNoteHistory.isEmpty;
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
