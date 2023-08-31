import 'dart:typed_data';

import 'package:fleeting_notes_flutter/models/note_history.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

import '../../models/Note.dart';
import '../../models/search_query.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
import '../../widgets/shortcuts.dart';
import 'components/backlinks_drawer.dart';
import 'components/note_editor_app_bar.dart';
import 'note_editor.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.extraNote,
    this.attachment,
  });

  final String noteId;
  final Note? extraNote;
  final Uint8List? attachment;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

bool isChecklistFormat(String line) {
  return RegExp(r'^\s*- \[.\] ').hasMatch(line);
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  bool autofocus = false;
  bool previewEnabled = false;
  bool checkListEnabled = false;
  Note? note;
  Uri? currentLoc;
  List<Note> backlinks = [];
  SearchQuery backlinksSq = SearchQuery();
  List<String> checkedItems = [];
  List<String> uncheckedItems = [];

  Future<void> initNoteScreen(NoteHistory? noteHistory) async {
    if (!mounted || !GoRouter.of(context).location.startsWith('/note/')) return;
    final db = ref.read(dbProvider);
    var tempNote = await getNote();
    noteHistory?.currNote = tempNote;
    if (createCheckList(tempNote.content)) {
      previewEnabled = true;
      checkListEnabled = true;
    }
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

  Note? noteFromPath(Uri? path) {
    if (path == null || !isValidUuid(path.pathSegments.last)) return null;
    var params = path.queryParameters;
    var newNote = Note.empty(
      id: path.pathSegments.last,
      title: params['title'] ?? '',
      content: params['content'] ?? '',
      source: params['source'] ?? '',
    );
    if (newNote.sourceMetadata.isEmpty) {
      newNote.sourceTitle = params['source_title'];
      newNote.sourceDescription = params['source_description'];
      newNote.sourceImageUrl = params['source_image_url'];
    }
    return newNote;
  }

  Future<Note> getNote() async {
    // initialize shared
    final db = ref.read(dbProvider);
    final noteUtils = ref.read(noteUtilsProvider);
    final nh = ref.read(noteHistoryProvider);
    Note? currNote = nh.currNote;
    String noteId = currNote?.id ?? widget.noteId;
    String pathNoteId = currentLoc?.pathSegments.last ?? '';
    if (isValidUuid(pathNoteId)) {
      noteId = pathNoteId;
    }
    Note? unsavedNote = db.settings.get('unsaved-note');
    Note? newNote = (unsavedNote?.id == noteId)
        ? unsavedNote
        : await db.getNoteById(noteId);
    if (newNote == null) {
      var params = currentLoc?.queryParameters ?? {};
      newNote = (currNote?.id == noteId) ? currNote : noteFromPath(currentLoc);
      bool appendSameSource =
          db.settings.get('append-same-source', defaultValue: true);
      // find note with same source and append content
      String qpSource = params['source'] ?? '';
      String qpContent = params['content'] ?? '';
      if (qpSource.isNotEmpty && appendSameSource) {
        final query = SearchQuery(
            searchByContent: false,
            searchByTitle: false,
            sortBy: SortOptions.modifiedDESC,
            query: qpSource,
            limit: null);
        Note? queriedNote;
        if (unsavedNote?.source == qpSource) {
          queriedNote = unsavedNote;
        } else {
          List<Note> notes = await db.getSearchNotes(query);
          queriedNote = notes.firstWhereOrNull((n) => n.source == qpSource);
        }
        if (queriedNote != null) {
          if (qpContent.isNotEmpty) {
            if (note?.id == queriedNote.id) {
              contentController.text += '\n$qpContent';
            }
            queriedNote.content += "\n$qpContent";
            noteUtils.setUnsavedNote(context, queriedNote, saveUnsaved: true);
          }
          autofocus = true;
          return queriedNote;
        }
      }
      newNote = newNote ?? Note.empty(id: noteId);
      if (!newNote.isEmpty()) {
        noteUtils.setUnsavedNote(context, newNote, saveUnsaved: true);
      }
      autofocus = true;
    }

    return newNote;
  }

  bool createCheckList(text) {
    if (text.isEmpty) {
      return false;
    }
    if (!text.startsWith("- [")) {
      return false;
    }
    uncheckedItems.clear();
    checkedItems.clear();
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        if (isChecklistFormat(line)) {
          final content = line.substring(6).trim();
          if (line.contains('- [x]')) {
            checkedItems.add(content);
          } else {
            uncheckedItems.add(content);
          }
        } else {
          uncheckedItems.clear();
          checkedItems.clear();
          return false;
        }
      }
    }
    return checkedItems.isNotEmpty || uncheckedItems.isNotEmpty;
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

  void onCheckListEnabled() {
    setState(() {
      uncheckedItems.clear();
      checkedItems.clear();
      contentController.text = "- [ ] ";
      uncheckedItems.add("");
      previewEnabled = true;
      checkListEnabled = true;
    });
  }

  void onPreview() {
    setState(() {
      if (!previewEnabled) {
        checkListEnabled = createCheckList(contentController.text);
      } else if (checkListEnabled) {
        uncheckedItems.clear();
        checkedItems.clear();
        checkListEnabled = false;
      }
      previewEnabled = !previewEnabled;
    });
  }

  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = StyleableTextFieldController(
    styles: TextPartStyleDefinitions(definitionList: [
      TextPartStyleDefinition(
          pattern: Note.linkRegex,
          style: const TextStyle(
            color: Color.fromARGB(255, 138, 180, 248),
            decoration: TextDecoration.underline,
          )),
      TextPartStyleDefinition(
          pattern: Note.tagRegex,
          style: const TextStyle(
            color: Colors.grey,
          )),
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
    return Shortcuts(
      shortcuts: noteShortcutMapping,
      child: WillPopScope(
        onWillPop: () async {
          if (renderNote == null) return true;
          onClose();
          return false;
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
                    onPreview: onPreview,
                    isMarkdownPreviewSelected: previewEnabled,
                    onBacklinks: (backlinks.isEmpty)
                        ? null
                        : scaffoldKey.currentState?.openEndDrawer,
                    contentController: contentController,
                    titleController: titleController,
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
                            autofocus: autofocus,
                            previewEnabled: previewEnabled,
                            padding: const EdgeInsets.only(
                                left: 24, right: 24, bottom: 16),
                            attachment: widget.attachment,
                            checkedItems: checkedItems,
                            uncheckedItems: uncheckedItems,
                            checkListEnabled: checkedItems.isNotEmpty ||
                                uncheckedItems.isNotEmpty ||
                                checkListEnabled,
                            onCheckListEnabled: onCheckListEnabled),
                  ),
                  if (bottomAppBarVisible)
                    KeyboardVisibilityBuilder(builder: (context, isVisible) {
                      if (isVisible) return const SizedBox.shrink();
                      return NoteEditorBottomAppBar(
                        onBack: (noteHistory.backNoteHistory.isEmpty)
                            ? null
                            : onBack,
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
      ),
    );
  }
}
