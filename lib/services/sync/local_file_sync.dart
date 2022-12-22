import 'dart:async';
import 'package:watcher/watcher.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:fleeting_notes_flutter/services/sync/sync_manager.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import "package:yaml/yaml.dart";
import 'package:collection/collection.dart';

class MDFile {
  YamlMap frontmatter = YamlMap();
  String content;
  MDFile(this.frontmatter, this.content);
}

bool isValidUuid(String uuid) {
  try {
    Uuid.parse(uuid);
    return true;
  } on FormatException {
    return false;
  }
}

class LocalFileSync extends SyncTerface {
  LocalFileSync({
    required this.settings,
    this.fs = const LocalFileSystem(),
  }) : super();
  final Settings settings;
  final FileSystem fs;
  Map<String, String> idToPath = {};
  bool get enabled => settings.get('local-sync-enabled', defaultValue: false);
  String get syncDir => settings.get('local-sync-dir', defaultValue: '');
  String get syncType =>
      settings.get('local-sync-type', defaultValue: 'two-way');
  String? get template => settings.get('local-sync-template');
  Stream<WatchEvent> get dirStream => Watcher(syncDir).events;
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
    List<Note> fsNotes = [];
    await setNoteIdToPathMapping();
    var notesToUpdate = await SyncManager.getNotesToUpdate(notes, getNotesByIds,
        shouldCreateNote: true);
    await upsertNotes(notesToUpdate);
    await Future.wait(idToPath.values.map((path) {
      var f = fs.file(path);
      return parseFile(f).then((value) {
        if (value != null) {
          fsNotes.add(value);
        }
      });
    }));

    // add directory listener
    if (syncType == 'two-way') {
      streamController.add(NoteEvent(fsNotes, NoteEventStatus.init));
      directoryStream = dirStream.listen((e) async {
        if (!canSync) return;
        switch (e.type) {
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
            // for adding or modifying we upsert
            var f = fs.file(e.path);
            var note = await parseFile(f);
            if (note != null && isValidUuid(note.id)) {
              idToPath[note.id] = e.path;
              streamController.add(NoteEvent([note], NoteEventStatus.upsert));
            }
            break;
        }
      });
    }
  }

  @override
  Future<void> upsertNotes(Iterable<Note> notes) async {
    for (var n in notes) {
      String mdContent = n.getMarkdownContent(template: template);
      File f;
      if (idToPath.containsKey(n.id)) {
        f = fs.file(idToPath[n.id] as String);
      } else {
        String fileName = n.getMarkdownFilename();
        f = fs.file(p.join(syncDir, fileName));
      }
      try {
        await f.writeAsString(mdContent);
        idToPath[n.id] = f.path;
      } on FileSystemException {
        // if (e.osError?.errorCode != 17) rethrow;
        // try writing as a different filename... weird bug / workaround
        var newFileName = "${const Uuid().v4()}.md";
        f = fs.file(p.join(syncDir, newFileName));
        await f.writeAsString(mdContent);
        idToPath[n.id] = f.path;
      }
    }
  }

  @override
  Future<void> deleteNotes(Iterable<String> ids) async {
    for (var id in ids) {
      if (idToPath.containsKey(id)) {
        var f = fs.file(idToPath[id] as String);
        idToPath.remove(id);
        try {
          await f.delete();
        } on FileSystemException catch (e) {
          debugPrint(e.toString());
        }
      }
    }
  }

  @override
  Future<Iterable<Note?>> getNotesByIds(Iterable<String> ids) async {
    List<Note> notes = [];
    await Future.wait(ids.map((id) {
      var path = idToPath[id];
      if (path == null) return Future.value(null);
      var f = fs.file(path);
      return parseFile(f).then((n) {
        if (n != null) notes.add(n);
      });
    }));
    return notes;
  }

  Future<void> setNoteIdToPathMapping() async {
    List<FileSystemEntity> files = await fs.directory(syncDir).list().toList();
    for (var f in files) {
      if (f is File && f.basename.endsWith(".md")) {
        try {
          String mdStr = await f.readAsString();
          MDFile md = parseMDFile(mdStr);
          var frontmatterId = md.frontmatter['id'];
          if (frontmatterId != null) {
            idToPath[frontmatterId] = f.path;
          }
        } on FileSystemException catch (e) {
          debugPrint(e.toString());
        }
      }
    }
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

  Future<Note?> parseFile(File f) async {
    String mdStr;
    try {
      mdStr = await f.readAsString();
    } on FileSystemException catch (e) {
      debugPrint(e.toString());
      return null;
    }
    var md = parseMDFile(mdStr);
    var stats = await f.stat();

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
