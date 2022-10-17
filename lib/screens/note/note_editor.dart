import 'dart:async';
import 'dart:typed_data';

import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';

import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:path/path.dart' as p;
import 'package:fleeting_notes_flutter/screens/note/components/header.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container_web.dart';
import 'package:flutter/services.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    Key? key,
    required this.note,
    required this.db,
    this.isShared = false,
  }) : super(key: key);

  final Note note;
  final Database db;
  final bool isShared;
  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> with RouteAware {
  List<Note> backlinkNotes = [];
  List<String> linkSuggestions = [];
  bool hasNewChanges = false;
  bool isNoteShareable = false;
  Timer? saveTimer;

  late bool autofocus;
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController sourceController;

  @override
  void initState() {
    super.initState();
    resetSaveTimer();
    hasNewChanges = widget.isShared;
    isNoteShareable = widget.note.isShareable;
    autofocus = widget.note.isEmpty() || widget.isShared;
    titleController = TextEditingController(text: widget.note.title);
    sourceController = TextEditingController(text: widget.note.source);
    contentController = StyleableTextFieldController(
      styles: TextPartStyleDefinitions(definitionList: [
        TextPartStyleDefinition(
            pattern: Note.linkRegex,
            style: const TextStyle(
              color: Color.fromARGB(255, 138, 180, 248),
              decoration: TextDecoration.underline,
            ))
      ]),
    );
    contentController.text = widget.note.content;
    widget.db.getBacklinkNotes(widget.note).then((notes) {
      setState(() {
        backlinkNotes = notes;
      });
    });
  }

  void resetSaveTimer() {
    var saveMs = widget.db.settings.get('save-delay-ms');
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
    widget.db.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    super.dispose();
    saveTimer?.cancel();
    widget.db.routeObserver.unsubscribe(this);
    if (hasNewChanges && !widget.isShared) {
      _saveNote(updateState: false);
    }
  }

  @override
  void didPopNext() {
    // Refresh note if we traverse back
    widget.db.getNote(widget.note.id).then((note) {
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

  // Helper functions
  Future<void> checkTitle(id, title) async {
    if (title == '') return;

    RegExp r = RegExp('[${Note.invalidChars}]');
    final invalidMatch = r.firstMatch(titleController.text);
    final titleExists =
        await widget.db.titleExists(widget.note.id, titleController.text);

    if (invalidMatch != null) {
      titleController.text = widget.note.title;
      throw FleetingNotesException(
          r'Title cannot contain [, ], #, *, :, ^, \, /');
    } else if (titleExists) {
      titleController.text = widget.note.title;
      throw FleetingNotesException(
          'Title `${widget.note.title}` already exists');
    }
  }

  void _deleteNote() async {
    Note deletedNote = widget.note;
    deletedNote.isDeleted = true;
    bool isSuccessDelete = await widget.db.deleteNotes([widget.note]);
    if (isSuccessDelete) {
      Navigator.pop(context);
      widget.db.noteHistory.remove(widget.note);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fail to delete note'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _saveNote({updateState = true}) async {
    Note updatedNote = widget.note;
    String prevTitle = widget.note.title;
    updatedNote.title = titleController.text;
    updatedNote.content = contentController.text;
    updatedNote.source = sourceController.text;
    updatedNote.isShareable = isNoteShareable;
    try {
      try {
        await checkTitle(updatedNote.id, updatedNote.title);
      } on FleetingNotesException catch (_) {
        titleController.text = prevTitle;
        rethrow;
      }
      if (updateState) {
        setState(() {
          hasNewChanges = false;
        });
      }
      bool isSaveSuccess = await widget.db.upsertNote(updatedNote);
      if (!isSaveSuccess) {
        if (updateState) onChanged();
        throw FleetingNotesException('Failed to save note');
      } else {
        widget.db.settings.delete('unsaved-note');
        await updateBacklinks(prevTitle, updatedNote.title);
      }
    } on FleetingNotesException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void storeUnsavedNote() {
    Note unsavedNote = Note(
      id: widget.note.id,
      title: titleController.text,
      content: contentController.text,
      source: sourceController.text,
      timestamp: widget.note.timestamp,
    );
    widget.db.settings.set('unsaved-note', unsavedNote);
  }

  Future<void> updateBacklinks(String prevTitle, String newTitle) async {
    if (backlinkNotes.isEmpty || prevTitle == newTitle) return;
    // update backlinks
    List<Note> updatedBacklinks = backlinkNotes.map((n) {
      RegExp r = RegExp('\\[\\[$prevTitle\\]\\]', multiLine: true);
      n.content = n.content.replaceAll(r, '[[${widget.note.title}]]');
      return n;
    }).toList();
    if (await widget.db.upsertNotes(updatedBacklinks)) {
      setState(() {
        backlinkNotes = updatedBacklinks;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${backlinkNotes.length} Link(s) Updated'),
        duration: const Duration(seconds: 2),
      ));
    } else {
      throw FleetingNotesException('Failed to update backlinks');
    }
  }

  void onChanged() async {
    if (widget.note.content != contentController.text ||
        widget.note.title != titleController.text ||
        widget.note.source != sourceController.text) {
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

  void onSearchNavigate(BuildContext context) {
    widget.db.popAllRoutes();
    widget.db.navigateToSearch('');
  }

  void onCopyUrl() {
    Clipboard.setData(ClipboardData(
        text: p.join(
            "https://my.fleetingnotes.app/", "?note=${widget.note.id}")));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('URL copied to clipboard'),
      duration: Duration(seconds: 2),
    ));
  }

  void onAddAttachment(String filename, Uint8List? bytes) async {
    try {
      String newFileName = '${widget.note.id}/$filename';
      String? downloadUrl =
          await widget.db.supabase.addAttachment(newFileName, bytes);
      if (mounted) {
        sourceController.text = downloadUrl;
        onChanged();
      }
    } on FleetingNotesException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    var isSharedNotes = widget.db.shareUserId != null;
    return Actions(
      actions: <Type, Action<Intent>>{
        SaveIntent: CallbackAction(onInvoke: (Intent intent) {
          if (hasNewChanges) {
            _saveNote();
          }
          return null;
        }),
      },
      child: Scaffold(
        body: Container(
          color: Theme.of(context).dialogBackgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                Header(
                  onSave: (hasNewChanges) ? _saveNote : null,
                  onDelete: (isSharedNotes) ? null : _deleteNote,
                  onSearch: () => onSearchNavigate(context),
                  onAddAttachment: onAddAttachment,
                  onCopyUrl: (widget.db.isLoggedIn() || isSharedNotes)
                      ? onCopyUrl
                      : null,
                  onShareChange: (bool isShareable) {
                    setState(() {
                      isNoteShareable = isShareable;
                    });
                    _saveNote();
                  },
                  isNoteShareable: isNoteShareable,
                ),
                const Divider(thickness: 1, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    padding: EdgeInsets.all(
                        Theme.of(context).custom.kDefaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.note.getDateTimeStr(),
                          style: Theme.of(context).textTheme.caption,
                        ),
                        TitleField(
                          controller: titleController,
                          onChanged: onChanged,
                        ),
                        ContentField(
                          controller: contentController,
                          db: widget.db,
                          onChanged: onChanged,
                          autofocus: autofocus,
                        ),
                        SourceContainer(
                          controller: sourceController,
                          onChanged: onChanged,
                          db: widget.db,
                          overrideSourceUrl: widget.note.isEmpty(),
                        ),
                        SizedBox(
                            height: Theme.of(context).custom.kDefaultPadding),
                        const Text("Backlinks", style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
                        SizedBox(
                            height:
                                Theme.of(context).custom.kDefaultPadding / 2),
                        ...backlinkNotes.map((note) => NoteCard(
                              note: note,
                              onLongPress: () => {},
                              onTap: () {
                                widget.db
                                    .navigateToNote(note); // TODO: Deprecate
                              },
                            )),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
