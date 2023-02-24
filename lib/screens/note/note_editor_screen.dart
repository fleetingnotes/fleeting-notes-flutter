import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/Note.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
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
  bool nonExistantNote = false;

  Future<Note> getNote() async {
    // initialize shared
    final db = ref.read(dbProvider);
    Note? note = await db.getNoteById(widget.noteId);
    if (note == null) {
      note = widget.extraNote ?? Note.empty(id: widget.noteId);

      // add browser extension stuff
      // final be = ref.read(browserExtensionProvider);
      // String selectionText = await be.getSelectionText();
      // if (selectionText.isNotEmpty) {
      //   String sourceUrl = await be.getSourceUrl();
      //   note.content = (note.content.isEmpty) ? selectionText : note.content;
      //   note.source = (note.source.isEmpty) ? sourceUrl : note.source;
      // }

      if (!note.isEmpty()) {
        db.settings.set('unsaved-note', note);
      }
      nonExistantNote = true;
    }
    titleController.text = note.title;
    contentController.text = note.content;
    sourceController.text = note.source;
    return note;
  }

  void onBack() async {
    final noteUtils = ref.read(noteUtilsProvider);
    noteUtils.onPopNote(context, widget.noteId);
    var currLoc = GoRouter.of(context).location;
    var noteId = currLoc.split('?').first.replaceFirst('/note/', '');
    final forwardNoteHistory = ref.read(forwardNoteProvider.notifier);
    forwardNoteHistory.state = [...forwardNoteHistory.state, noteId];
    noteUtils.backNoteHistory.removeLast();
    context.pop();
  }

  void onForward() async {
    final noteUtils = ref.read(noteUtilsProvider);
    final db = ref.read(dbProvider);

    final forwardNoteHistory = ref.read(forwardNoteProvider.notifier);
    var newForwardNoteHistory = [...forwardNoteHistory.state];
    var noteId = newForwardNoteHistory.removeLast();
    forwardNoteHistory.state = [...newForwardNoteHistory];
    Note? note = await db.getNoteById(noteId);
    if (note != null) {
      noteUtils.navigateToNote(context, note);
    }
  }

  void onClose() {
    final noteUtils = ref.read(noteUtilsProvider);
    noteUtils.onPopNote(context, widget.noteId);
    context.go('/');
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
    final forwardNoteHistory = ref.watch(forwardNoteProvider);
    return FutureBuilder<Note>(
      future: getNote(),
      builder: (context, snapshot) {
        Note? note = snapshot.data;
        return WillPopScope(
          onWillPop: () async {
            if (note == null) return true;
            onClose();
            return false;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoteEditorAppBar(
                note: note,
                onClose: onClose,
                onBack: (noteUtils.backNoteHistory.isNotEmpty) ? onBack : null,
                onForward: (forwardNoteHistory.isNotEmpty) ? onForward : null,
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
                        autofocus: nonExistantNote,
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
