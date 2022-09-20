import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:path/path.dart' as p;

class LocalSync {
  LocalSync({
    required this.settings,
  }) : super();
  final Settings settings;

  void pushNotes(List<Note> notes) {
    if (!canSync()) {
      throw FleetingNotesException('Local sync failed: Check settings');
    }
    String syncDir = settings.get('local-sync-dir');
    String template = settings.get('local-sync-template');
    for (var n in notes) {
      String fileName = n.getMarkdownFilename();
      String mdContent = n.getMarkdownContent(template: template);
      var f = File(p.join(syncDir, fileName));
      f.writeAsString(mdContent);
    }
  }

  bool canSync() {
    bool enabled = settings.get('local-sync-enabled', defaultValue: false);
    bool syncDirNotEmpty =
        (settings.get('local-sync-dir', defaultValue: '') as String).isNotEmpty;
    return enabled && syncDirNotEmpty;
  }
}
