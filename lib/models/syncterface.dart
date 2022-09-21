import 'Note.dart';

abstract class SyncTerface {
  void pushNotes(List<Note> notes);
  void deleteNotes(List<Note> notes);
  bool canSync();
}
