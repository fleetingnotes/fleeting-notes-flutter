import 'package:fleeting_notes_flutter/screens/note/components/note_popup_menu.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/large_note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../models/Note.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({super.key});

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  handleTap(Note note) async {
    showDialog(
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
                onDelete: () => handleDeleteNote(note),
                onCopyUrl: () => handleCopyUrl(note),
                onShareChange: (bool shareable) =>
                    handleShareChange(note, shareable),
                isNoteShareable: note.isShareable,
              )
            ],
          ),
          content: Container(width: 600, child: NoteEditor(note: note)),
        );
      },
    );
  }

  handleShareChange(Note note, bool shareable) async {
    final db = ref.read(dbProvider);
    var newNote = await db.getNoteById(note.id);
    if (newNote != null) {
      newNote.isShareable = shareable;
      await db.upsertNotes([newNote]);
    }
  }

  handleDeleteNote(Note note) async {
    final db = ref.read(dbProvider);
    note.isDeleted = true;
    bool isSuccessDelete = await db.deleteNotes([note]);
    if (!isSuccessDelete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete note'),
      ));
    }
  }

  handleCopyUrl(Note note) async {
    final db = ref.read(dbProvider);
    var newNote = await db.getNoteById(note.id);
    if (newNote != null) {
      newNote.isShareable = true;
      await db.upsertNotes([newNote]);
      Clipboard.setData(ClipboardData(
          text: p.join("https://my.fleetingnotes.app/", "?note=${note.id}")));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('URL copied to clipboard'),
      ));
    }
  }

  handleSourcePress() {}

  handleMenuPress() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Dialog(
          child: Text('handleMenuPress'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(viewedNotesProvider);
    return ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, i) {
          return LargeNoteCard(
              note: notes[i],
              onTap: handleTap,
              onSourcePress: handleSourcePress,
              onMenuPress: handleMenuPress,
              onCopyUrl: () => handleCopyUrl(notes[i]),
              onDelete: () => handleDeleteNote(notes[i]),
              onShareChange: (bool shareable) =>
                  handleShareChange(notes[i], shareable));
        });
  }
}
