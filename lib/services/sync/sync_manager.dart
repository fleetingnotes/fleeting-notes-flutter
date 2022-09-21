import 'package:fleeting_notes_flutter/models/syncterface.dart';
import '../../models/Note.dart';
import '../settings.dart';
import 'local_sync.dart';

class SyncManager {
  List<SyncTerface> allSyncs = [];
  final Settings settings;
  SyncManager({
    required this.settings,
  }) {
    allSyncs = [
      LocalSync(settings: settings),
    ];
  }
  void pushNotes(List<Note> notes) {
    for (var s in allSyncs) {
      if (s.canSync()) {
        s.pushNotes(notes);
      }
    }
  }

  void deleteNotes(List<Note> notes) {
    for (var s in allSyncs) {
      if (s.canSync()) {
        s.deleteNotes(notes);
      }
    }
  }
}
