import 'package:fleeting_notes_flutter/services/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/Note.dart';
import '../screens/note/components/note_popup_menu.dart';
import '../screens/note/note_editor.dart';
import 'database.dart';
import 'package:path/path.dart' as p;

// utilities to help do things with notes
class NoteUtils {
  Database db;
  NoteNotifier noteNotifier;
  NoteUtils(this.db, this.noteNotifier);

  void handleCopyUrl(BuildContext context, String noteId) async {
    var note = await db.getNoteById(noteId);
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not find note'),
      ));
      return;
    }
    note.isShareable = true;
    await db.upsertNotes([note]);
    Clipboard.setData(ClipboardData(
        text: p.join("https://my.fleetingnotes.app/", "?note=${note.id}")));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('URL copied to clipboard'),
    ));
  }

  void handleDeleteNote(BuildContext context, String noteId) async {
    var note = await db.getNoteById(noteId);
    noteNotifier.deleteNotes([noteId]);
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not find note'),
      ));
      return;
    }
    bool isSuccessDelete = await db.deleteNotes([note]);
    if (!isSuccessDelete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete note'),
      ));
    }
  }

  void handleShareChange(String noteId, bool shareable) async {
    var note = await db.getNoteById(noteId);
    if (note != null) {
      note.isShareable = shareable;
      await db.upsertNotes([note]);
    }
  }

  void openNoteEditorDialog(BuildContext context, Note note) async {
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
}
