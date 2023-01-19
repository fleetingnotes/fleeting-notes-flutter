import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container_web.dart';

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({
    Key? key,
    required this.note,
    this.titleController,
    this.contentController,
    this.sourceController,
    this.isShared = false,
    this.padding,
  }) : super(key: key);

  final Note note;
  final bool isShared;
  final TextEditingController? titleController;
  final TextEditingController? contentController;
  final TextEditingController? sourceController;
  final EdgeInsetsGeometry? padding;

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  List<String> linkSuggestions = [];
  bool hasNewChanges = false;
  bool isNoteShareable = false;
  Timer? saveTimer;
  DateTime modifiedAt = DateTime(2000);
  DateTime? savedAt;
  StreamSubscription<NoteEvent>? noteChangeStream;

  late bool autofocus;
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
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    routeObserver = db.routeObserver;
    hasNewChanges = widget.isShared;
    isNoteShareable = widget.note.isShareable;
    autofocus = widget.note.isEmpty() || widget.isShared;

    // update controllers
    titleController = widget.titleController ?? titleController;
    contentController = widget.contentController ?? contentController;
    sourceController = widget.sourceController ?? sourceController;
    titleController.text = widget.note.title;
    contentController.text = widget.note.content;
    sourceController.text = widget.note.source;

    noteChangeStream = db.noteChangeController.stream.listen(handleNoteEvent);
    modifiedAt = DateTime.parse(widget.note.modifiedAt);
  }

  void resetSaveTimer() {
    final settings = ref.read(settingsProvider);
    var saveMs = settings.get('save-delay-ms');
    saveTimer?.cancel();
    saveTimer = Timer(Duration(milliseconds: saveMs), () {
      if (hasNewChanges) {
        _saveNote();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    saveTimer?.cancel();
    noteChangeStream?.cancel();
  }

  @override
  void didPopNext() {
    final db = ref.read(dbProvider);
    // Refresh note if we traverse back
    db.getNote(widget.note.id).then((note) {
      if (note != null) {
        titleController.text = note.title;
        contentController.text = note.content;
        sourceController.text = note.source;
      }
    });
  }

  @override
  void didPushNext() {
    // Autosave if the note was previously saved
    // If we autosave every note, we would pollute pretty fast.
    if (hasNewChanges) {
      _saveNote();
    }
  }

  Future<void> _saveNote() async {
    final noteUtils = ref.read(noteUtilsProvider);
    Note updatedNote = widget.note.copyWith(
      title: titleController.text,
      content: contentController.text,
      source: sourceController.text,
    );
    try {
      setState(() {
        hasNewChanges = false;
      });
      await noteUtils.handleSaveNote(context, updatedNote);
      setState(() {
        savedAt = DateTime.now();
      });
    } on FleetingNotesException {
      onChanged();
    }
  }

  void storeUnsavedNote() {
    final db = ref.read(dbProvider);
    Note unsavedNote = Note(
      id: widget.note.id,
      title: titleController.text,
      content: contentController.text,
      source: sourceController.text,
      createdAt: widget.note.createdAt,
    );
    db.settings.set('unsaved-note', unsavedNote);
  }

  void onChanged() async {
    modifiedAt = DateTime.now().toUtc();
    bool isNoteDiff = widget.note.content != contentController.text ||
        widget.note.title != titleController.text ||
        widget.note.source != sourceController.text;
    bool isNoteEmpty = contentController.text.isEmpty &&
        titleController.text.isEmpty &&
        sourceController.text.isEmpty;
    if (isNoteDiff && !isNoteEmpty) {
      if (titleController.text.isNotEmpty ||
          contentController.text.isNotEmpty) {
        storeUnsavedNote();
      }
      setState(() {
        hasNewChanges = true;
      });
      resetSaveTimer();
    } else {
      setState(() {
        hasNewChanges = false;
      });
    }
  }

  void handleNoteEvent(NoteEvent e) {
    Note? n = e.notes.firstWhereOrNull((n) => n.id == widget.note.id);
    if (n == null) return;
    isNoteShareable = n.isShareable;
    bool noteSimilar = titleController.text == n.title &&
        contentController.text == n.content &&
        sourceController.text == n.source;
    bool isNewerNote = DateTime.parse(n.modifiedAt)
        // add 5 second buffer to prevent prevent notes updating as user types
        .subtract(const Duration(seconds: 5))
        .isAfter(modifiedAt);
    if (!noteSimilar && !n.isDeleted && isNewerNote) {
      updateFields(n);
    }
  }

  void updateFields(Note n) {
    var prevTitleSel = titleController.selection;
    var prevContentSel = contentController.selection;
    var prevSourceSel = sourceController.selection;
    titleController.text = n.title;
    contentController.text = n.content;
    sourceController.text = n.source;
    // attempt to reset selection
    try {
      titleController.selection = prevTitleSel;
      contentController.selection = prevContentSel;
      sourceController.selection = prevSourceSel;
    } catch (e) {
      debugPrint('Failed to set cursor position (${e.toString()})');
      debugPrint('Putting cursor at end of string');
      var titleLen = titleController.text.length;
      var contentLen = contentController.text.length;
      var sourceLen = sourceController.text.length;
      titleController.selection =
          TextSelection(baseOffset: titleLen, extentOffset: titleLen);
      contentController.selection =
          TextSelection(baseOffset: contentLen, extentOffset: contentLen);
      sourceController.selection =
          TextSelection(baseOffset: sourceLen, extentOffset: sourceLen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        SaveIntent: CallbackAction(onInvoke: (Intent intent) {
          if (hasNewChanges) {
            _saveNote();
          }
          return null;
        }),
      },
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TitleField(
                  controller: titleController,
                  onChanged: onChanged,
                ),
                ContentField(
                  controller: contentController,
                  onChanged: onChanged,
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                SourceContainer(
                  controller: sourceController,
                  onChanged: onChanged,
                  overrideSourceUrl: widget.note.isEmpty(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
