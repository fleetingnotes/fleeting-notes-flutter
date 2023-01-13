import 'package:fleeting_notes_flutter/services/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/Note.dart';
import '../models/exceptions.dart';
import '../screens/note/components/note_popup_menu.dart';
import '../screens/note/note_editor.dart';
import 'database.dart';
import 'package:path/path.dart' as p;

// utilities to help do things with notes
class NoteUtils {
  Database db;
  NoteNotifier noteNotifier;
  NoteUtils(this.db, this.noteNotifier);

  Future<void> handleCopyUrl(BuildContext context, String noteId) async {
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
    try {
      noteNotifier.deleteNotes(notes.map((n) => n.id));
      bool isSuccessDelete = await db.deleteNotes(notes);
      if (!isSuccessDelete) {
        throw FleetingNotesException('Failed to delete note');
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      rethrow;
    }
  }

  Future<void> handleSaveNote(BuildContext context, Note note) async {
    try {
      await _checkTitle(note.id, note.title);
      bool isSaveSuccess = await db.upsertNotes([note], setModifiedAt: true);
      if (!isSaveSuccess) {
        throw FleetingNotesException('Failed to save note');
      } else {
        db.settings.delete('unsaved-note');
        await updateBacklinks(context, note);
      }
    } on FleetingNotesException catch (e) {
      _showSnackbar(context, e.message);
      rethrow;
    }
  }

  Future<void> handleShareChange(String noteId, bool shareable) async {
    var note = await db.getNoteById(noteId);
    if (note != null) {
      note.isShareable = shareable;
      await db.upsertNotes([note]);
    }
  }

  Future<List<Note>> updateBacklinks(BuildContext context, Note newNote) async {
    var oldNote = await db.getNoteById(newNote.id);
    if (oldNote == null || oldNote.title == newNote.title) {
      return [];
    }

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

  Future<void> openNoteEditorDialog(BuildContext context, Note note) async {
    var dbNote = await db.getNoteById(note.id);
    if (dbNote != null) {
      note = dbNote;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 8),
              const Text("Edit Note"),
              const Spacer(),
              NotePopupMenu(
                note: note,
              )
            ],
          ),
          content: SizedBox(width: 599, child: NoteEditor(note: note)),
        );
      },
    );
    // TODO: make it so that notes are saved when dialog is closed in case dialog closed early
    var postDialogNote = await db.getNoteById(note.id);
    if (postDialogNote != null) {
      noteNotifier.addNote(postDialogNote);
    }
  }

  // helpers
  Future<void> _checkTitle(id, title) async {
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
    ));
  }
}
