import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({
    Key? key,
    required this.note,
    this.titleController,
    this.contentController,
    this.sourceController,
    this.autofocus = false,
    this.padding,
  }) : super(key: key);

  final Note note;
  final bool autofocus;
  final TextEditingController? titleController;
  final TextEditingController? contentController;
  final TextEditingController? sourceController;
  final EdgeInsetsGeometry? padding;

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  List<String> linkSuggestions = [];
  Note currNote = Note.empty();
  bool hasNewChanges = false;
  bool isNoteShareable = false;
  Timer? saveTimer;
  DateTime modifiedAt = DateTime(2000);
  DateTime? savedAt;
  StreamSubscription<NoteEvent>? noteChangeStream;
  StreamSubscription? authChangeStream;
  UrlMetadata? sourceMetadata;

  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  TextEditingController sourceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    hasNewChanges = widget.autofocus;
    isNoteShareable = widget.note.isShareable;

    // update controllers
    titleController = widget.titleController ?? titleController;
    contentController = widget.contentController ?? contentController;
    sourceController = widget.sourceController ?? sourceController;

    noteChangeStream = db.noteChangeController.stream.listen(handleNoteEvent);
    authChangeStream =
        db.supabase.authChangeController.stream.listen(handleAuthChange);
    modifiedAt = DateTime.parse(widget.note.modifiedAt);
  }

  void initSourceMetadata(UrlMetadata metadata) {
    if (metadata.url.isNotEmpty) {
      if (!metadata.isEmpty) {
        if (!mounted) return;
        setState(() {
          sourceMetadata = metadata;
        });
      } else {
        updateSourceMetadata(widget.note.source);
      }
    }
  }

  void resetSaveTimer({int? defaultSaveMs, bool updateMetadata = true}) async {
    final db = ref.read(dbProvider);
    final settings = ref.read(settingsProvider);
    // if note has not been created don't save
    final dbNote = await db.getNoteById(widget.note.id);
    if (dbNote == null) {
      return;
    }
    int saveMs = defaultSaveMs ?? settings.get('save-delay-ms');
    saveTimer?.cancel();
    saveTimer = Timer(Duration(milliseconds: saveMs), () async {
      await _saveNote();
      if (updateMetadata) {
        await updateSourceMetadata(sourceController.text);
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
    authChangeStream?.cancel();
    contentController.removeListener(onChanged);
  }

  Future<void> _saveNote() async {
    final noteUtils = ref.read(noteUtilsProvider);
    Note updatedNote = widget.note.copyWith(
      title: titleController.text,
      content: contentController.text,
      source: sourceController.text,
    );
    // populate source metadata!
    if (sourceMetadata != null) {
      updatedNote.sourceTitle = sourceMetadata?.title;
      updatedNote.sourceDescription = sourceMetadata?.description;
      updatedNote.sourceImageUrl = sourceMetadata?.imageUrl;
    }

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

  Note getNote() {
    Note note = Note(
      id: widget.note.id,
      title: titleController.text,
      content: contentController.text,
      source: sourceController.text,
      createdAt: widget.note.createdAt,
    );
    if (sourceMetadata?.url == sourceController.text) {
      note.sourceTitle = sourceMetadata?.title;
      note.sourceDescription = sourceMetadata?.description;
      note.sourceImageUrl = sourceMetadata?.imageUrl;
    }
    return note;
  }

  void storeUnsavedNote() {
    final noteUtils = ref.read(noteUtilsProvider);
    noteUtils.setUnsavedNote(context, getNote());
  }

  void onChanged() async {
    final noteUtils = ref.read(noteUtilsProvider);
    modifiedAt = DateTime.now().toUtc();
    final db = ref.read(dbProvider);
    Note unsavedNote = db.settings.get('unsaved-note') ??
        (await db.getNoteById(widget.note.id)) ??
        widget.note;
    bool isNoteDiff = unsavedNote.content != contentController.text ||
        unsavedNote.title != titleController.text ||
        unsavedNote.source != sourceController.text;
    if (isNoteDiff) {
      noteUtils.cachedNote = getNote();
      storeUnsavedNote();
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

  void handleAuthChange(_) {
    updateFields(Note.empty());
  }

  void onClearSource() {
    sourceMetadata = null;
    sourceController.text = '';
    onChanged();
  }

  Future<void> updateSourceMetadata(String url) async {
    UrlMetadata? m = sourceMetadata;
    if (url.isNotEmpty && m?.url != sourceController.text) {
      final db = ref.read(dbProvider);
      m = await db.supabase.getUrlMetadata(url);
    }
    if (!mounted) return;
    setState(() {
      sourceMetadata = (m?.isEmpty == true) ? null : m;
    });
    resetSaveTimer(defaultSaveMs: 0, updateMetadata: false);
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

  void initCurrNote() async {
    if (currNote.id == widget.note.id) return;
    contentController.removeListener(onChanged);
    saveTimer?.cancel();
    sourceMetadata = null;
    currNote = widget.note;

    titleController.text = currNote.title;
    contentController.text = currNote.content;
    sourceController.text = currNote.source;

    contentController.addListener(onChanged);
    var db = ref.read(dbProvider);
    if (db.settings.get('unsaved-note') != null &&
        await db.getNoteById(currNote.id) != null) {
      resetSaveTimer();
    }
    initSourceMetadata(currNote.sourceMetadata);
  }

  @override
  Widget build(BuildContext context) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final db = ref.watch(dbProvider);
    initCurrNote();
    return Actions(
      actions: <Type, Action<Intent>>{
        SaveIntent: CallbackAction(onInvoke: (Intent intent) {
          if (db.settings.get('unsaved-note') != null) {
            saveTimer?.cancel();
            _saveNote();
          }
          return null;
        }),
      },
      child: KeyboardVisibilityBuilder(builder: (context, kbVisible) {
        return Padding(
          padding:
              (kbVisible) ? const EdgeInsets.only(bottom: 36) : EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.note.getShortDateTimeStr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  TitleField(
                    controller: titleController,
                    onChanged: onChanged,
                  ),
                  SourceContainer(
                    controller: sourceController,
                    metadata: sourceMetadata,
                    onChanged: onChanged,
                    onClearSource: onClearSource,
                  ),
                  const Divider(),
                  ContentField(
                    controller: contentController,
                    onChanged: onChanged,
                    autofocus: widget.autofocus,
                    onPop: () => noteUtils.onPopNote(context, widget.note.id),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
