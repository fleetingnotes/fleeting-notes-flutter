import 'package:fleeting_notes_flutter/models/note_history.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
  });

  final String noteId;
  final Note? extraNote;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  bool nonExistantNote = false;
  Note? note;
  Uri? currentLoc;
  List<Note> backlinks = [];
  SearchQuery backlinksSq = SearchQuery();

  Future<void> initNoteScreen(NoteHistory? noteHistory) async {
    if (!mounted || !GoRouter.of(context).location.startsWith('/note/')) return;
    final db = ref.read(dbProvider);
    var tempNote = await getNote();
    noteHistory?.currNote = tempNote;

    // get backlinks (async)
    if (tempNote.title.isNotEmpty) {
      backlinksSq = SearchQuery(query: "[[${tempNote.title}]]");
      setState(() {
        note = tempNote;
      });
      db.getSearchNotes(backlinksSq).then((notes) {
        setState(() {
          backlinks = notes;
        });
      });
    } else {
      setState(() {
        note = tempNote;
        backlinks = [];
      });
    }

    // add to noteHistory if empty and location correct
    if (noteHistory?.isEmpty == true) {
      final noteHistoryNotifier = ref.read(noteHistoryProvider.notifier);
      noteHistoryNotifier.addNote(context, tempNote);
    }
  }

  Future<Note> getNote() async {
    // initialize shared
    final db = ref.read(dbProvider);
    final nh = ref.read(noteHistoryProvider);
    Note? currNote = nh.currNote;
    String noteId = currNote?.id ?? widget.noteId;
    String pathNoteId = currentLoc?.pathSegments.last ?? '';
    if (isValidUuid(pathNoteId)) {
      noteId = pathNoteId;
    }
    Note? newNote = await db.getNoteById(noteId);
    if (newNote == null) {
      var extraNote = widget.extraNote;
      newNote = currNote;
      bool appendSameSource =
          db.settings.get('append-same-source', defaultValue: true);
      // find note with same source and append content
      String qpSource = currentLoc?.queryParameters['source'] ?? '';
      String qpContent = currentLoc?.queryParameters['content'] ?? '';
      if (qpSource.isNotEmpty && appendSameSource) {
        final query = SearchQuery(
            searchByContent: false,
            searchByTitle: false,
            sortBy: SortOptions.modifiedDESC,
            query: qpSource,
            limit: 1);
        List<Note> notes = await db.getSearchNotes(query);
        if (notes.isNotEmpty) {
          newNote = notes.first;
          if (qpContent.isNotEmpty) {
            newNote.content += "\n$qpContent";
            return newNote;
          }
        }
      }
      newNote = newNote ?? extraNote ?? Note.empty(id: noteId);
      if (!newNote.isEmpty()) {
        db.settings.set('unsaved-note', newNote);
      }
      nonExistantNote = true;
    }

    return newNote;
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
    final renderNote = note;
    bool bottomAppBarVisible = !noteHistory.isHistoryEmpty;
    if (currentLoc?.toString() != GoRouter.of(context).location) {
      currentLoc = Uri.parse(GoRouter.of(context).location);
      initNoteScreen(noteHistory);
    }
    return WillPopScope(
      onWillPop: () async {
        if (renderNote == null) return true;
        onClose();
        return true;
      },
      child: ScaffoldMessenger(
        child: Scaffold(
          key: scaffoldKey,
          resizeToAvoidBottomInset: false,
          drawerScrimColor: Colors.transparent,
          endDrawer: BacklinksDrawer(
            closeDrawer: scaffoldKey.currentState?.closeEndDrawer,
            backlinks: backlinks,
            searchQuery: backlinksSq,
          ),
          body: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NoteEditorAppBar(
                  note: renderNote,
                  onClose: onClose,
                  onBacklinks: (backlinks.isEmpty)
                      ? null
                      : scaffoldKey.currentState?.openEndDrawer,
                  contentController: contentController,
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: (renderNote == null)
                      ? const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()))
                      : NoteEditor(
                          note: renderNote,
                          titleController: titleController,
                          contentController: contentController,
                          sourceController: sourceController,
                          autofocus: nonExistantNote,
                          padding: const EdgeInsets.only(
                              left: 24, right: 24, bottom: 16),
                        ),
                ),
                if (bottomAppBarVisible)
                  KeyboardVisibilityBuilder(builder: (context, isVisible) {
                    if (isVisible) return const SizedBox.shrink();
                    return NoteEditorBottomAppBar(
                      onBack:
                          (noteHistory.backNoteHistory.isEmpty) ? null : onBack,
                      onForward: (noteHistory.forwardNoteHistory.isEmpty)
                          ? null
                          : onForward,
                    );
                  })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
