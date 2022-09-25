import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import "package:yaml/yaml.dart";

class NotionSync extends SyncTerface {
  NotionSync({
    required this.settings,
  }) : super();
  final Settings settings;
  bool get enabled => settings.get('local-sync-enabled', defaultValue: false);
  String get notionToken => settings.get('notion-token-dir', defaultValue: '');
  String? get notionDatabaseId => settings.get('notion-sync-template');

  @override
  bool canSync() {
    return enabled && notionToken.isNotEmpty && notionDatabaseId != null;
  }

  @override
  void pushNotes(List<Note> notes) {
    print('NotionSync: pushNotes');
    // var idToPath = getNoteIdToPathMapping();
    // for (var n in notes) {
    //   String mdContent = n.getMarkdownContent(template: template);
    //   File f;
    //   if (idToPath.containsKey(n.id)) {
    //     f = File(idToPath[n.id] as String);
    //   } else {
    //     String fileName = n.getMarkdownFilename();
    //     f = File(p.join(syncDir, fileName));
    //   }
    //   f.writeAsString(mdContent);
    // }
  }

  @override
  void deleteNotes(List<Note> notes) {
    // var idToPath = getNoteIdToPathMapping();
    // for (var n in notes) {
    //   if (idToPath.containsKey(n.id)) {
    //     var f = File(idToPath[n.id] as String);
    //     f.delete();
    //   }
    // }
  }

}
