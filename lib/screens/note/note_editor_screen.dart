import 'dart:typed_data';

import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/Note.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
import '../../utils/responsive.dart';
import 'components/note_popup_menu.dart';
import 'note_editor.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.extraNote,
  });

  final String noteId;
  final Note? extraNote;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  bool noteWasShared = false;

  Future<Note> getNote() async {
    // initialize shared
    final db = ref.read(dbProvider);
    Note? note = await db.getNoteById(widget.noteId);
    if (note == null) {
      note = widget.extraNote;
      noteWasShared = true;
    }
    note = note ?? Note.empty(id: widget.noteId);
    return note;
  }

  Future<bool> onWillPop(String noteId) async {
    final db = ref.watch(dbProvider);
    final noteUtils = ref.read(noteUtilsProvider);
    final noteNotifier = ref.read(viewedNotesProvider.notifier);
    Note? unsavedNote = db.settings.get('unsaved-note');
    if (unsavedNote != null && unsavedNote.id == noteId) {
      await noteUtils.handleSaveNote(context, unsavedNote);
      noteNotifier.addNote(unsavedNote);
    } else {
      Note? postDialogNote = await db.getNoteById(noteId);
      if (postDialogNote != null) {
        noteNotifier.addNote(postDialogNote);
      }
    }
    return true;
  }

  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = StyleableTextFieldController(
    styles: TextPartStyleDefinitions(definitionList: [
      TextPartStyleDefinition(
          pattern: Note.linkRegex,
          style: const TextStyle(
            color: Color.fromARGB(255, 138, 180, 248),
            decoration: TextDecoration.underline,
          ))
    ]),
  );
  TextEditingController sourceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final noteUtils = ref.watch(noteUtilsProvider);
    return FutureBuilder<Note>(
      future: getNote(),
      builder: (context, snapshot) {
        Note? note = snapshot.data;
        return WillPopScope(
          onWillPop: () async {
            if (note == null) return true;
            return onWillPop(widget.noteId);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                elevation:
                    (Responsive.isMobile(context)) ? null : dialogElevation,
                leading: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
                title: Text("Edit Note",
                    style: Theme.of(context).textTheme.titleLarge),
                actions: [
                  ValueListenableBuilder(
                      valueListenable:
                          settings.box.listenable(keys: ['unsaved-note']),
                      builder: (context, Box box, _) {
                        var unsavedNote = box.get('unsaved-note');
                        bool saveEnabled = unsavedNote != null &&
                            note != null &&
                            unsavedNote?.id == note.id;
                        return IconButton(
                            onPressed: (saveEnabled)
                                ? () {
                                    noteUtils.handleSaveNote(
                                        context, unsavedNote);
                                  }
                                : null,
                            icon: const Icon(Icons.save));
                      }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: NotePopupMenu(
                      note: note,
                      onAddAttachment: (String fn, Uint8List? fb) {
                        if (note == null) return;
                        noteUtils.onAddAttachment(context, note, fn, fb,
                            controller: contentController);
                      },
                    ),
                  )
                ],
              ),
              Flexible(
                fit: FlexFit.loose,
                child: (note == null)
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()))
                    : NoteEditor(
                        note: note,
                        titleController: titleController,
                        contentController: contentController,
                        sourceController: sourceController,
                        isShared: noteWasShared,
                        padding: const EdgeInsets.only(
                            left: 24, right: 24, bottom: 16),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
