import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/screens/note/components/CheckListField/check_list_field.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({
    Key? key,
    required this.note,
    this.titleController,
    this.contentController,
    this.sourceController,
    this.autofocus = false,
    this.previewEnabled = false,
    this.padding,
    this.attachment,
    this.checkedItems,
    this.uncheckedItems,
    this.checkListEnabled = false,
  }) : super(key: key);

  final bool previewEnabled;
  final Note note;
  final bool autofocus;
  final TextEditingController? titleController;
  final TextEditingController? contentController;
  final TextEditingController? sourceController;
  final EdgeInsetsGeometry? padding;
  final Uint8List? attachment;
  final List<String>? checkedItems;
  final List<String>? uncheckedItems;
  final bool checkListEnabled;

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

  void onUploadAttachment(Uint8List? attachment) async {
    if (attachment == null) return;
    final noteLoading = ref.read(noteLoadingProvider.notifier);
    noteLoading.update((_) => true);
    final db = ref.read(dbProvider);
    var sourceUrl = await db.uploadAttachment(fileBytes: attachment);
    sourceController.text = sourceUrl;
    noteLoading.update((_) => false);
    onChanged();
  }

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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onUploadAttachment(widget.attachment);
    });
  }

  void initSourceMetadata(UrlMetadata metadata) async {
    final noteUtils = ref.read(noteUtilsProvider);
    final noteLoading = ref.read(noteLoadingProvider.notifier);
    if (metadata.url.isNotEmpty) {
      if (!metadata.isEmpty) {
        if (!mounted) return;
        setState(() {
          sourceMetadata = metadata;
        });
      } else {
        String source = widget.note.source;
        if (!kIsWeb) {
          var sourceFile = File(source);
          if (!noteLoading.state && sourceFile.existsSync()) {
            noteLoading.update((_) => true);
            var bytes = await sourceFile.readAsBytes();
            source =
                (await noteUtils.uploadAttachment(context, fileBytes: bytes)) ??
                    source;
            sourceController.text = source;
            onChanged();
            noteLoading.update((_) => false);
          }
        }
        updateSourceMetadata(source);
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
      if (mounted) {
        setState(() {
          hasNewChanges = false;
        });
      }
      await noteUtils.handleSaveNote(context, updatedNote);
      if (mounted) {
        setState(() {
          savedAt = DateTime.now();
        });
      }
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

  void updateFields(Note n, {bool setUnsaved = false}) {
    var prevTitleSel = titleController.selection;
    var prevContentSel = contentController.selection;
    var prevSourceSel = sourceController.selection;
    bool hasChanges = false;
    if (n.title != titleController.text) {
      titleController.text = n.title;
      hasChanges = true;
    }
    if (n.content != contentController.text) {
      contentController.text = n.content;
      hasChanges = true;
    }
    if (n.source != sourceController.text) {
      sourceController.text = n.source;
      hasChanges = true;
    }
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
    if (hasChanges && setUnsaved) onChanged();
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

  void onCommandRun(String alias) async {
    final noteUtils = ref.read(noteUtilsProvider);
    final noteLoading = ref.read(noteLoadingProvider.notifier);
    String body = '';
    var note = getNote();
    try {
      noteLoading.update((_) => true);
      final res = await noteUtils.callPluginFunction(note, alias);
      if (!mounted) return;
      body = res.body;
      if (res.statusCode != 200) {
        throw FleetingNotesException("${res.statusCode}: ${res.body}");
      }
      final data = jsonDecode(res.body);
      final noteObj = data?['note'];
      if (data['note'] == null) {
        throw const FormatException('Insert body as string');
      }
      var newNote = note.copyWith(
        title: noteObj?['title'],
        content: noteObj?['content'],
        source: noteObj?['source'],
      );
      updateFields(newNote, setUnsaved: true);
    } on FleetingNotesException catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Command Error'),
          content: Text(e.message),
        ),
      );
    } on FormatException {
      // insert data in contentController
      var currIndex = contentController.selection.extentOffset;
      var t = contentController.text;
      contentController.text =
          t.substring(0, currIndex) + body + t.substring(currIndex, t.length);
      contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: currIndex + body.length));
    }
    noteLoading.update((_) => false);
  }

  // TODO: fix work around (https://github.com/fleetingnotes/fleeting-notes-flutter/pull/906)
  String get replacedText {
    return contentController.text
        .replaceAll(RegExp(r"- \[ \] ?(\n|$)"), "- [ ]\n")
        .replaceAll(RegExp(r"- \[x\] ?(\n|$)"), "- [x]\n");
  }

  @override
  Widget build(BuildContext context) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final db = ref.watch(dbProvider);
    bool autoFocusTitle =
        db.settings.get('auto-focus-title', defaultValue: true);
    TextDirection textDirection =
        db.settings.get('right-to-left', defaultValue: false)
            ? TextDirection.rtl
            : TextDirection.ltr;
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
                  Text(widget.note.getShortDateTimeStr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  TitleField(
                      controller: titleController,
                      onChanged: onChanged,
                      autofocus: autoFocusTitle &&
                          contentController.text.isEmpty &&
                          titleController.text.isEmpty,
                      textDirection: textDirection),
                  ExcludeFocusTraversal(
                    child: SourceContainer(
                        controller: sourceController,
                        metadata: sourceMetadata,
                        onChanged: onChanged,
                        onClearSource: onClearSource,
                        textDirection: textDirection),
                  ),
                  const Divider(),
                  if (widget.previewEnabled && !widget.checkListEnabled)
                    Markdown(
                      data: replacedText,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8),
                    ),
                  if (widget.checkListEnabled)
                    ChecklistField(
                      checkedItems: widget.checkedItems ?? [],
                      controller: contentController,
                      uncheckedItems: widget.uncheckedItems ?? [],
                      onChanged: onChanged,
                    ),
                  if (!widget.previewEnabled && !widget.checkListEnabled)
                    ContentField(
                      controller: contentController,
                      onChanged: onChanged,
                      onPop: () => noteUtils.onPopNote(context, widget.note.id),
                      onCommandRun: onCommandRun,
                      autofocus: !autoFocusTitle &&
                          contentController.text.isEmpty &&
                          titleController.text.isEmpty,
                      textDirection: textDirection,
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
