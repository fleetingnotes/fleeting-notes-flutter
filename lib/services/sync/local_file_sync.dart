import 'dart:async';
import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:watcher/watcher.dart';
import "package:yaml/yaml.dart";
import 'package:collection/collection.dart';

class MDFile {
  YamlMap frontmatter = YamlMap();
  String content;
  MDFile(this.frontmatter, this.content);
}

class LocalFileSync extends SyncTerface {
  LocalFileSync({
    required this.settings,
  }) : super();
  final Settings settings;
  Map<String, String> idToPath = {};
  bool get enabled => settings.get('local-sync-enabled', defaultValue: false);
  String get syncDir => settings.get('local-sync-dir', defaultValue: '');
  String? get template => settings.get('local-sync-template');
  StreamSubscription<WatchEvent>? directoryStream;
  final StreamController<NoteEvent> streamController =
      StreamController.broadcast();

  @override
  Stream<NoteEvent> get noteStream => streamController.stream;
  @override
  bool get canSync => enabled && syncDir.isNotEmpty;

  @override
  Future<void> init({Iterable<Note> notes = const Iterable.empty()}) async {
    directoryStream?.cancel();
    if (!canSync) return;

    // initial two-way sync
    var notesToUpdate =
        await getNotesToUpdate(notes, getNotesByIds, shouldCreateNote: true);
    upsertNotes(notesToUpdate);
    idToPath = getNoteIdToPathMapping();
    var fsNotes = idToPath.values.map((path) {
      var f = File(path);
      return parseFile(f);
    }).whereType<Note>();
    streamController.add(NoteEvent(fsNotes, NoteEventStatus.init));

    // add directory listener
    directoryStream = DirectoryWatcher(syncDir).events.listen((e) {
      if (!canSync) return;
      switch (e.type) {
        case ChangeType.MODIFY:
          var f = File(e.path);
          var note = parseFile(f);
          if (note != null) {
            streamController.add(NoteEvent([note], NoteEventStatus.upsert));
          }
          break;
        case ChangeType.REMOVE:
          String? noteId =
              idToPath.keys.firstWhereOrNull((k) => idToPath[k] == e.path);
          if (noteId != null) {
            var deletedNote = Note.createDeletedNote(noteId);
            streamController
                .add(NoteEvent([deletedNote], NoteEventStatus.delete));
          }
          break;
        default:
      }
    });
  }

  @override
  Future<void> upsertNotes(Iterable<Note> notes) async {
    for (var n in notes) {
      String mdContent = n.getMarkdownContent(template: template);
      File f;
      if (idToPath.containsKey(n.id)) {
        f = File(idToPath[n.id] as String);
      } else {
        String fileName = n.getMarkdownFilename();
        f = File(p.join(syncDir, fileName));
      }
      try {
        f.writeAsStringSync(mdContent);
        idToPath[n.id] = f.path;
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode != 17) rethrow;
        // try writing as a different filename... weird bug / workaround
        var newFileName = "${const Uuid().v4()}.md";
        f = File(p.join(syncDir, newFileName));
        f.writeAsStringSync(mdContent);
        idToPath[n.id] = f.path;
      }
    }
  }

  @override
  Future<void> deleteNotes(Iterable<String> ids) async {
    for (var id in ids) {
      if (idToPath.containsKey(id)) {
        var f = File(idToPath[id] as String);
        idToPath.remove(id);
        f.deleteSync();
      }
    }
  }

  @override
  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids) async {
    return ids.map((id) {
      var path = idToPath[id];
      if (path == null) return null;
      var f = File(path);
      return parseFile(f);
    });
  }

  Map<String, String> getNoteIdToPathMapping() {
    List<FileSystemEntity> files = Directory(syncDir).listSync();
    Map<String, String> idToPathMap = {};
    for (var f in files) {
      if (f is File) {
        try {
          String mdStr = f.readAsStringSync();
          MDFile md = parseMDFile(mdStr);
          var frontmatterId = md.frontmatter['id'];
          if (frontmatterId != null) {
            idToPathMap[frontmatterId] = f.path;
          }
        } on FileSystemException catch (e) {
          debugPrint(e.toString());
        }
      }
    }
    return idToPathMap;
  }

  MDFile parseMDFile(String md) {
    var r = RegExp(r"^---\n([\s\S]*?)\n---\n", multiLine: true);
    var m = r.firstMatch(md);
    YamlMap frontmatter = YamlMap();
    String content = md;
    if (m != null) {
      String yamlStr = m.group(1) ?? '';
      String entireFrontmatter = m.group(0) ?? '';
      try {
        frontmatter = loadYaml(yamlStr) ?? YamlMap();
        content = content.replaceFirst(entireFrontmatter, '');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return MDFile(frontmatter, content);
  }

  Note? parseFile(File f) {
    String mdStr;
    try {
      mdStr = f.readAsStringSync();
    } on FileSystemException catch (e) {
      debugPrint(e.toString());
      return null;
    }
    var md = parseMDFile(mdStr);
    var stats = f.statSync();

    // note properties
    var noteId = md.frontmatter['id'];
    var title = md.frontmatter['title']?.toString() ?? '';
    var source = md.frontmatter['source']?.toString() ?? '';
    var modifiedAt = stats.modified.toUtc().toIso8601String();
    if (noteId != null) {
      var note = Note(
        id: noteId.toString(),
        title: title,
        content: md.content,
        source: source,
        createdAt: modifiedAt,
      );
      note.modifiedAt = modifiedAt;
      return note;
    }
    return null;
  }
}
