import 'dart:convert';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/Note.dart';
import '../models/exceptions.dart';
import 'package:path/path.dart' as p;

// utilities to help do things with notes
class NoteUtils {
  ProviderRef ref;
  NoteUtils(this.ref);
  Note cachedNote = Note.empty();
  List<String> backNoteHistory = [];

  Future<void> handleCopyUrl(BuildContext context, String noteId) async {
    final db = ref.read(dbProvider);
    var note = await db.getNoteById(noteId);
    if (note == null) {
      _showSnackbar(context, 'Could not find note');
      return;
    }
    note.isShareable = true;
    await db.upsertNotes([note]);
    Clipboard.setData(ClipboardData(
        text: p.join("https://my.fleetingnotes.app/", "?note=${note.id}")));
    _showSnackbar(context, 'URL copied to clipboard');
  }

  Future<bool> handleDeleteNote(BuildContext context, List<Note> notes) async {
    final db = ref.read(dbProvider);
    try {
      bool isSuccessDelete = await db.deleteNotes(notes);
      if (!isSuccessDelete) {
        throw FleetingNotesException('Failed to delete note');
      }
      return true;
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      return false;
    }
  }

  Future<void> handleSaveNote(BuildContext context, Note note) async {
    final db = ref.read(dbProvider);
    try {
      var oldNote = await db.getNoteById(note.id);
      await _checkTitle(context, note.id, note.title);
      bool isSaveSuccess = await db.upsertNotes([note], setModifiedAt: true);
      if (!isSaveSuccess) {
        throw FleetingNotesException('Failed to save note');
      } else {
        db.settings.delete('unsaved-note');
        await updateBacklinks(context, oldNote, note);
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      return;
    }
  }

  Future<void> handleShareChange(String noteId, bool shareable) async {
    final db = ref.read(dbProvider);
    var note = await db.getNoteById(noteId);
    if (note != null) {
      note.isShareable = shareable;
      await db.upsertNotes([note]);
    }
  }

  Future<List<Note>> updateBacklinks(
      BuildContext context, Note? oldNote, Note newNote) async {
    RegExp r = RegExp('[${Note.invalidChars}]');
    if (oldNote == null ||
        oldNote.title == newNote.title ||
        oldNote.title.isEmpty ||
        newNote.title.isEmpty ||
        r.hasMatch(newNote.title)) {
      return [];
    }

    final db = ref.read(dbProvider);
    var allNotes = await db.getAllNotes();
    // update backlinks
    List<Note> updatedBacklinks = [];
    for (var n in allNotes) {
      if (n.content.contains('[[${oldNote.title}]]')) {
        n.content = n.content.replaceAll(r, '[[${newNote.title}]]');
        updatedBacklinks.add(n);
      }
    }
    if (await db.upsertNotes(updatedBacklinks, setModifiedAt: true)) {
      if (updatedBacklinks.isNotEmpty) {
        _showSnackbar(context, '${updatedBacklinks.length} link(s) updated');
      }
      return updatedBacklinks;
    } else {
      throw FleetingNotesException('Failed to update backlinks');
    }
  }

  Future<String?> uploadAttachment(BuildContext context,
      {String? filename, Uint8List? fileBytes}) async {
    final db = ref.read(dbProvider);
    try {
      return await db.uploadAttachment(
          filename: filename, fileBytes: fileBytes);
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
    }
    return null;
  }

  Future<http.Response> callPluginFunction(Note note, String alias) async {
    final db = ref.read(dbProvider);
    List<dynamic> allCommands = db.settings.get('plugin-slash-commands') ?? [];
    var commandSettings =
        allCommands.firstWhereOrNull((command) => command['alias'] == alias) ??
            {};
    if (!commandSettings.containsKey('commandId')) {
      throw FleetingNotesException('Command ID not found for alias: $alias');
    }
    var commandId = commandSettings['commandId'];
    final url =
        Uri.https("fleeting-notes-plugins.deno.dev", "plugins/$commandId");
    dynamic metadata = commandSettings['metadata'] ?? '';
    try {
      metadata = jsonDecode(metadata);
      // ignore: empty_catches
    } on FormatException {}
    Map<String, dynamic> body = {
      "metadata": metadata,
      "note": note.toJson(),
    };
    try {
      var res = await db.httpClient.post(
        url,
        body: jsonEncode(body),
        headers: {
          "Authorization": "Bearer ${db.supabase.currSession?.accessToken}",
          "Content-Type": "application/json",
        },
      );
      return res;
    } catch (e) {
      throw FleetingNotesException('Failed to call plugin `$commandId`: $e');
    }
  }

  void onAddAttachment(
      BuildContext context, Note note, String filename, Uint8List? bytes,
      {TextEditingController? controller}) async {
    final db = ref.read(dbProvider);
    try {
      String newFileName = '${note.id}/$filename';
      Note? newNote = await db.addAttachmentToNewNote(
          filename: newFileName, fileBytes: bytes);
      if (newNote != null) {
        if (controller != null) {
          db.insertTextAtSelection(controller, "[[${newNote.title}]]");
        } else {
          var dbNote = await db.getNoteById(note.id);
          if (dbNote != null) {
            dbNote.content += '\n[[${newNote.title}]]';
            await handleSaveNote(context, dbNote);
          }
        }
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
    }
  }

  void launchURLBrowser(String url, BuildContext context) async {
    void _failUrlSnackbar(String message) {
      var snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
    }
  }

  // helpers
  Future<void> _checkTitle(
      BuildContext context, String id, String title) async {
    final db = ref.read(dbProvider);
    if (title == '') return;

    RegExp r = RegExp('[${Note.invalidChars}]');
    final invalidMatch = r.firstMatch(title);
    final titleExists = await db.titleExists(id, title);

    if (invalidMatch != null) {
      _showSnackbar(context,
          r'Warning: Title contains invalid filename characters:  [, ], #, *, :, ^, \, /');
    } else if (titleExists) {
      _showSnackbar(context, 'Warning: Title `$title` already exists');
    }
  }

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(text),
      showCloseIcon: true,
    ));
  }

  void setUnsavedNote(BuildContext context, Note? note,
      {bool saveUnsaved = false}) async {
    final db = ref.read(dbProvider);
    Note? unsavedNote = db.settings.get('unsaved-note');
    if (saveUnsaved && unsavedNote != null) {
      await handleSaveNote(context, unsavedNote);
    }
    db.settings.set('unsaved-note', note);
  }

  Future<void> onPopNote(BuildContext context, String noteId) async {
    final db = ref.read(dbProvider);
    Note? unsavedNote = db.settings.get('unsaved-note');
    if (unsavedNote != null && unsavedNote.id == noteId) {
      await handleSaveNote(context, unsavedNote);
    }
  }
}
