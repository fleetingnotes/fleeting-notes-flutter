import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/Note.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
import '../../utils/responsive.dart';
import '../../widgets/dialog_page.dart';
import 'components/note_editor_app_bar.dart';
import 'note_editor.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.extraNote,
    this.appbarElevation,
  });

  final String noteId;
  final Note? extraNote;
  final double? appbarElevation;

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

  void popScreen() async {
    final noteUtils = ref.read(noteUtilsProvider);
    noteUtils.onPopNote(context, widget.noteId);
    context.pop();
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
    final noteUtils = ref.watch(noteUtilsProvider);
    return FutureBuilder<Note>(
      future: getNote(),
      builder: (context, snapshot) {
        Note? note = snapshot.data;
        return WillPopScope(
          onWillPop: () async {
            if (note == null) return true;
            noteUtils.onPopNote(context, widget.noteId);
            return true;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoteEditorAppBar(
                note: note,
                elevation:
                    Responsive.isMobile(context) ? null : dialogElevation,
                onClose: popScreen,
                contentController: contentController,
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
