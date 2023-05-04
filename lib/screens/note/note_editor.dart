import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/screens/note/components/content_editor.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({
    Key? key,
    required this.note,
    this.autofocus = false,
    this.padding,
  }) : super(key: key);

  final Note note;
  final bool autofocus;
  final EdgeInsetsGeometry? padding;

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  List<String> linkSuggestions = [];
  Note currNote = Note.empty();
  bool isNoteShareable = false;
  Timer? saveTimer;
  DateTime modifiedAt = DateTime(2000);
  StreamSubscription<NoteEvent>? noteChangeStream;
  StreamSubscription? authChangeStream;
  UrlMetadata? sourceMetadata;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    isNoteShareable = widget.note.isShareable;

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
    final ed = ref.read(editorProvider);
    // if note has not been created don't save
    final dbNote = await db.getNoteById(widget.note.id);
    if (dbNote == null) {
      return;
    }
    int saveMs = defaultSaveMs ?? settings.get('save-delay-ms');
    saveTimer?.cancel();
    saveTimer = Timer(Duration(milliseconds: saveMs), () async {
      if (!mounted) return;
      await _saveNote();
      if (updateMetadata) {
        await updateSourceMetadata(ed.sourceController.text);
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
  }

  Future<void> _saveNote() async {
    final noteUtils = ref.read(noteUtilsProvider);
    Note updatedNote = getNote();
    try {
      await noteUtils.handleSaveNote(context, updatedNote);
    } on FleetingNotesException {
      onChanged();
    }
  }

  Note getNote() {
    final ed = ref.read(editorProvider);
    String serializedContent = ed.serializeDocToMd(ed.contentDoc);
    Note note = widget.note.copyWith(
      title: ed.titleController.text,
      content: serializedContent,
      source: ed.sourceController.text,
    );
    // populate source metadata!
    if (sourceMetadata?.url == ed.sourceController.text) {
      note.sourceTitle = sourceMetadata?.title;
      note.sourceDescription = sourceMetadata?.description;
      note.sourceImageUrl = sourceMetadata?.imageUrl;
    }
    return note;
  }

  void storeUnsavedNote(Note note) {
    final noteUtils = ref.read(noteUtilsProvider);
    noteUtils.setUnsavedNote(context, note);
  }

  void onChanged() async {
    final noteUtils = ref.read(noteUtilsProvider);
    final ed = ref.read(editorProvider);
    modifiedAt = DateTime.now().toUtc();
    final db = ref.read(dbProvider);
    Note unsavedNote = db.settings.get('unsaved-note') ?? widget.note;
    noteUtils.cachedNote = getNote();
    bool isNoteDiff = unsavedNote.content != noteUtils.cachedNote.content ||
        unsavedNote.title != noteUtils.cachedNote.title ||
        unsavedNote.source != noteUtils.cachedNote.source;
    if (isNoteDiff) {
      storeUnsavedNote(noteUtils.cachedNote);
      resetSaveTimer(
          updateMetadata: unsavedNote.source != ed.sourceController.text);
    }
  }

  void refreshEditor(Note n) {
    final ed = ref.read(editorProvider);
    ed.updateFields(n);
  }

  void handleNoteEvent(NoteEvent e) {
    final ed = ref.read(editorProvider);
    Note? n = e.notes.firstWhereOrNull((n) => n.id == widget.note.id);
    if (n == null) return;
    isNoteShareable = n.isShareable;
    bool noteSimilar = ed.titleController.text == n.title &&
        ed.serializeDocToMd(ed.contentDoc) == n.content &&
        ed.sourceController.text == n.source;
    bool isNewerNote = DateTime.parse(n.modifiedAt)
        // add 5 second buffer to prevent prevent notes updating as user types
        .subtract(const Duration(seconds: 5))
        .isAfter(modifiedAt);
    if (!noteSimilar && !n.isDeleted && isNewerNote) {
      refreshEditor(n);
    }
  }

  void handleAuthChange(_) {
    refreshEditor(Note.empty());
  }

  void onClearSource() {
    final ed = ref.read(editorProvider);
    sourceMetadata = null;
    ed.sourceController.text = '';
    onChanged();
  }

  Future<void> updateSourceMetadata(String url) async {
    final ed = ref.read(editorProvider);
    UrlMetadata? m = sourceMetadata;
    if (url.isNotEmpty && m?.url != ed.sourceController.text) {
      final db = ref.read(dbProvider);
      m = await db.supabase.getUrlMetadata(url);
    }
    if (!mounted) return;
    setState(() {
      sourceMetadata = (m?.isEmpty == true) ? null : m;
    });
    resetSaveTimer(defaultSaveMs: 0, updateMetadata: false);
  }

  void initCurrNote() async {
    if (currNote.id == widget.note.id || !mounted) return;
    saveTimer?.cancel();
    sourceMetadata = null;
    currNote = widget.note;

    refreshEditor(currNote);
    var db = ref.read(dbProvider);
    if (db.settings.get('unsaved-note') != null &&
        await db.getNoteById(currNote.id) != null) {
      resetSaveTimer();
    }
    initSourceMetadata(currNote.sourceMetadata);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final ed = ref.watch(editorProvider);
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
                controller: ed.titleController,
                onChanged: onChanged,
              ),
              SourceContainer(
                controller: ed.sourceController,
                metadata: sourceMetadata,
                onChanged: onChanged,
                onClearSource: onClearSource,
              ),
              const Divider(),
              ContentEditor(
                doc: ed.contentDoc,
                autofocus: widget.autofocus,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
