import 'package:fleeting_notes_flutter/screens/note/components/note_editor_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/Note.dart';
import '../../models/search_query.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
import 'components/backlinks_drawer.dart';
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
  List<Note> backlinks = [];
  SearchQuery backlinksSq = SearchQuery();

  Future<Note> getNote(Note? currNote) async {
    // initialize shared
    final db = ref.read(dbProvider);
    final noteId = currNote?.id ?? widget.noteId;
    Note? note = await db.getNoteById(noteId);
    if (note == null) {
      note = currNote ?? widget.extraNote ?? Note.empty(id: noteId);
      if (!note.isEmpty()) {
        db.settings.set('unsaved-note', note);
      }
      nonExistantNote = true;
    }
    titleController.text = note.title;
    contentController.text = note.content;
    sourceController.text = note.source;

    // get backlinks (async)
    if (note.title.isNotEmpty) {
      backlinksSq = SearchQuery(query: "[[${note.title}]]");
      db.getSearchNotes(backlinksSq).then((notes) {
        backlinks = notes;
      });
    }

    // add to noteHistory if empty and location correct
    final noteHistory = ref.read(noteHistoryProvider);
    if (noteHistory.currNote == null &&
        GoRouter.of(context).location.startsWith('/note/')) {
      final noteHistoryNotifier = ref.read(noteHistoryProvider.notifier);
      noteHistoryNotifier.addNote(context, note);
    }

    return note;
  }

  void onBack() async {
    final noteUtils = ref.read(noteUtilsProvider);

    // update note history
    final noteHistoryNotifier = ref.read(noteHistoryProvider.notifier);
    Note? prevNote = noteHistoryNotifier.goBack(context);
    if (prevNote != null) {
      noteUtils.onPopNote(context, prevNote.id);
    }
  }

  void onForward() async {
    final noteUtils = ref.read(noteUtilsProvider);

    // update note history
    final noteHistoryNotifier = ref.read(noteHistoryProvider.notifier);
    Note? prevNote = noteHistoryNotifier.goForward(context);
    if (prevNote != null) {
      noteUtils.onPopNote(context, prevNote.id);
    }
  }

  void onClose() {
    final noteUtils = ref.read(noteUtilsProvider);
    final noteHistoryNotifier = ref.read(noteHistoryProvider.notifier);
    Note? prevNote = noteHistoryNotifier.goHome(context);
    if (prevNote != null) {
      noteUtils.onPopNote(context, prevNote.id);
    }
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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final noteHistory = ref.watch(noteHistoryProvider);
    return FutureBuilder<Note>(
      future: getNote(noteHistory.currNote),
      builder: (context, snapshot) {
        Note? note = snapshot.data;
        return WillPopScope(
          onWillPop: () async {
            if (note == null) return true;
            onClose();
            return true;
          },
          child: Scaffold(
            key: scaffoldKey,
            drawerScrimColor: Colors.transparent,
            endDrawer: BacklinksDrawer(
              closeDrawer: scaffoldKey.currentState?.closeEndDrawer,
              backlinks: backlinks,
              searchQuery: backlinksSq,
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NoteEditorAppBar(
                  note: note,
                  onClose: onClose,
                  onBacklinks: (backlinks.isEmpty)
                      ? null
                      : scaffoldKey.currentState?.openEndDrawer,
                  contentController: contentController,
                ),
                Flexible(
                  fit: FlexFit.tight,
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
                const Divider(),
                NoteEditorBottomAppBar(
                  onBack:
                      (noteHistory.backNoteHistory.isNotEmpty) ? onBack : null,
                  onForward: (noteHistory.forwardNoteHistory.isNotEmpty)
                      ? onForward
                      : null,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
