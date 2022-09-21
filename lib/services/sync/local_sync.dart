import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import "package:yaml/yaml.dart";

class LocalSync extends SyncTerface {
  LocalSync({
    required this.settings,
  }) : super();
  final Settings settings;
  bool get enabled => settings.get('local-sync-enabled', defaultValue: false);
  String get syncDir => settings.get('local-sync-dir', defaultValue: '');
  String? get template => settings.get('local-sync-template');

  @override
  bool canSync() {
    return enabled && syncDir.isNotEmpty;
  }

  @override
  void pushNotes(List<Note> notes) {
    var idToPath = getNoteIdToPathMapping();
    for (var n in notes) {
      String mdContent = n.getMarkdownContent(template: template);
      File f;
      if (idToPath.containsKey(n.id)) {
        f = File(idToPath[n.id] as String);
      } else {
        String fileName = n.getMarkdownFilename();
        f = File(p.join(syncDir, fileName));
      }
      f.writeAsString(mdContent);
    }
  }

  @override
  void deleteNotes(List<Note> notes) {
    var idToPath = getNoteIdToPathMapping();
    for (var n in notes) {
      if (idToPath.containsKey(n.id)) {
        var f = File(idToPath[n.id] as String);
        f.delete();
      }
    }
  }

  Map<String, String> getNoteIdToPathMapping() {
    List<FileSystemEntity> files = Directory(syncDir).listSync();
    Map<String, String> idToPathMap = {};
    for (var f in files) {
      if (f is File) {
        try {
          String mdStr = f.readAsStringSync();
          var md = parseMDFile(mdStr);
          Map frontmatter = md["frontmatter"];
          if (frontmatter.containsKey('id')) {
            idToPathMap[frontmatter['id']] = f.path;
          }
        } on FileSystemException catch (e) {
          debugPrint(e.toString());
        }
      }
    }
    return idToPathMap;
  }

  Map<String, dynamic> parseMDFile(String md) {
    var r = RegExp(r"^---\n([\s\S]*?)\n---\n", multiLine: true);
    var m = r.firstMatch(md);
    var parsedDict = {"frontmatter": {}, "content": ""};
    if (m != null) {
      String yamlStr = m.group(1) ?? '';
      String content = m.group(0) ?? '';
      parsedDict['frontmatter'] = loadYaml(yamlStr) ?? {};
      parsedDict['content'] = content.replaceFirst(yamlStr, '');
    }
    return parsedDict;
  }
}
