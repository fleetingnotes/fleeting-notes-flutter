import 'package:carousel_slider/carousel_controller.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/Note.dart';
import '../models/exceptions.dart';
import 'package:path/path.dart' as p;

// utilities to help do things with notes
class NoteUtils {
  ProviderRef ref;
  NoteUtils(this.ref);
  CarouselController carouselController = CarouselController();
  int currPageIndex = 0;
  Note cachedNote = Note.empty();

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

  Future<void> handleDeleteNote(BuildContext context, List<Note> notes) async {
    final db = ref.read(dbProvider);
    final noteNotifier = ref.read(viewedNotesProvider.notifier);
    try {
      bool isSuccessDelete = await db.deleteNotes(notes);
      if (!isSuccessDelete) {
        throw FleetingNotesException('Failed to delete note');
      }
      noteNotifier.deleteNotes(notes.map((n) => n.id));
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      rethrow;
    }
  }

  Future<void> handleSaveNote(BuildContext context, Note note) async {
    final db = ref.read(dbProvider);
    try {
      var oldNote = await db.getNoteById(note.id);
      await _checkTitle(note.id, note.title);
      bool isSaveSuccess = await db.upsertNotes([note], setModifiedAt: true);
      if (!isSaveSuccess) {
        throw FleetingNotesException('Failed to save note');
      } else {
        db.settings.delete('unsaved-note');
        await updateBacklinks(context, oldNote, note);
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      rethrow;
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
    if (oldNote == null || oldNote.title == newNote.title) {
      return [];
    }

    final db = ref.read(dbProvider);
    var allNotes = await db.getAllNotes();
    // update backlinks
    List<Note> updatedBacklinks = [];
    for (var n in allNotes) {
      RegExp r = RegExp('\\[\\[${oldNote.title}\\]\\]', multiLine: true);
      if (r.hasMatch(n.content)) {
        n.content = n.content.replaceAll(r, '[[${newNote.title}]]');
        updatedBacklinks.add(n);
      }
    }
    if (await db.upsertNotes(updatedBacklinks, setModifiedAt: true)) {
      _showSnackbar(context, '${updatedBacklinks.length} link(s) updated');
      return updatedBacklinks;
    } else {
      throw FleetingNotesException('Failed to update backlinks');
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
            db.upsertNotes([dbNote], setModifiedAt: true);
          }
        }
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
    }
  }

  Future<void> openNoteEditorDialog(BuildContext context, Note note) async {
    return context.goNamed('note', params: {'id': note.id}, extra: note);
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
      await launchUrl(uri);
    } catch (e) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
    }
  }

  // helpers
  Future<void> _checkTitle(id, title) async {
    final db = ref.read(dbProvider);
    if (title == '') return;

    RegExp r = RegExp('[${Note.invalidChars}]');
    final invalidMatch = r.firstMatch(title);
    final titleExists = await db.titleExists(id, title);

    if (invalidMatch != null) {
      throw FleetingNotesException(
          r'Title cannot contain [, ], #, *, :, ^, \, /');
    } else if (titleExists) {
      throw FleetingNotesException('Title `$title` already exists');
    }
  }

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(text),
      showCloseIcon: true,
    ));
  }

  // saves note and adds it to viewed notes if it makes sense to
  Future<void> onPopNote(BuildContext context, String noteId) async {
    final noteNotifier = ref.read(viewedNotesProvider.notifier);
    final viewedNotes = ref.read(viewedNotesProvider);
    final db = ref.read(dbProvider);
    try {
      if (viewedNotes[currPageIndex].id == noteId) return;
    } on RangeError catch (e) {
      debugPrint(e.toString());
    }

    try {
      if (viewedNotes.isEmpty && !cachedNote.isEmpty()) {
        noteNotifier.addNote(cachedNote);
      }
      Note? unsavedNote = db.settings.get('unsaved-note');
      if (unsavedNote != null && unsavedNote.id == noteId) {
        await handleSaveNote(context, unsavedNote);
        noteNotifier.addNote(unsavedNote);
        carouselController.jumpToPage(0);
      } else {
        Note? postDialogNote = await db.getNoteById(noteId);
        if (postDialogNote != null) {
          noteNotifier.addNote(postDialogNote);
          carouselController.jumpToPage(0);
        }
      }
      return;
    } on RangeError {
      return;
    }
  }
}
