import '../services/settings.dart';

class PinnedNotesManager {
  final Settings settingsProvider;
  final String key = "pinned-notes";

  PinnedNotesManager(this.settingsProvider);

  List<String> getPinnedNotes() {
    return (settingsProvider.get(key) as List? ?? [])
        .map((dynamic item) => item.toString())
        .toList();
  }

  void toggleNotePinned(String noteId) {
    final List<String> pinnedNotes = getPinnedNotes();

    if (pinnedNotes.contains(noteId)) {
      pinnedNotes.remove(noteId);
    } else {
      pinnedNotes.add(noteId);
    }

    updatePinnedNotes(pinnedNotes);
  }

  void updatePinnedNotes(List<String> notes) {
    settingsProvider.set(key, notes);
  }

  bool isNotePinned(String noteId) {
    final List<String> pinnedNotes = getPinnedNotes();
    return pinnedNotes.contains(noteId);
  }
}
