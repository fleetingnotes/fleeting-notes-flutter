import 'dart:async';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import '../settings.dart';

class SyncManager {
  List<SyncTerface> allSyncs;
  final Settings settings;
  final Stream<NoteEvent> mainSyncStream;
  final void Function(NoteEvent) handleSyncFromExternal;
  final List<StreamSubscription<NoteEvent>> streamSubs = [];
  SyncManager(
    this.allSyncs,
    this.mainSyncStream,
    this.handleSyncFromExternal,
    this.settings,
  ) {
    streamSubs.add(mainSyncStream.listen(handleSyncFromMain));
    for (var s in allSyncs) {
      streamSubs.add(s.noteStream.listen(handleSyncFromExternal));
      s.init();
    }
  }

  void handleSyncFromMain(NoteEvent e) async {
    for (var s in allSyncs) {
      if (!s.canSync) continue;
      var notesToUpdate = await getNotesToUpdate(e.notes, s.getNotesByIds);
      switch (e.status) {
        case NoteEventStatus.init:
          s.upsertNotes(notesToUpdate);
          break;
        case NoteEventStatus.upsert:
          s.upsertNotes(notesToUpdate);
          break;
        case NoteEventStatus.delete:
          s.deleteNotes(notesToUpdate);
          break;
      }
    }
  }
}
