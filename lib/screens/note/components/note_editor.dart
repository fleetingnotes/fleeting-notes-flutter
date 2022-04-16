import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

import 'package:fleeting_notes_flutter/widgets/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';

import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/screens/note/components/header.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/source_container.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/screens/note/components/source_container_web.dart';

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
  bool hasNewChanges = false;

  late bool autofocus;
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController sourceController;

  @override
  void initState() {
    super.initState();
    hasNewChanges = widget.isShared;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.db.routeObserver
        .subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    widget.db.routeObserver.unsubscribe(this);
    if (hasNewChanges) _saveNote(updateState: false);
    super.dispose();
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
    if (hasNewChanges) _saveNote();
  }

  // Helper functions
  Future<String> checkTitle(id, title) async {
    String errMessage = '';
    if (title == '') return errMessage;

    RegExp r = RegExp('[${Note.invalidChars}]');
    final invalidMatch = r.firstMatch(titleController.text);
    final titleExists =
        await widget.db.titleExists(widget.note.id, titleController.text);

    if (invalidMatch != null) {
      errMessage = 'Title cannot contain [, ], #, *';
      titleController.text = widget.note.title;
    } else if (titleExists) {
      errMessage = 'Title `${titleController.text}` already exists';
      titleController.text = widget.note.title;
    }
    return errMessage;
  }

  void _deleteNote() async {
    Note deletedNote = widget.note;
    deletedNote.isDeleted = true;
    bool isSuccessDelete = await widget.db.deleteNote(widget.note);
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

  Future<String> _saveNote({updateState = true}) async {
    Note updatedNote = widget.note;
    String prevTitle = widget.note.title;
    updatedNote.title = titleController.text;
    updatedNote.content = contentController.text;
    updatedNote.source = sourceController.text;
    FocusManager.instance.primaryFocus?.unfocus();
    String errMessage = await checkTitle(updatedNote.id, updatedNote.title);
    if (errMessage == '') {
      if (updateState) {
        setState(() {
          hasNewChanges = false;
        });
      }
      bool isSaveSuccess = await widget.db.upsertNote(updatedNote);
      if (!isSaveSuccess) {
        errMessage = 'Failed to save note';
        if (updateState) onChanged();
      } else if (backlinkNotes.isNotEmpty) {
        // update backlinks
        List<Note> updatedBacklinks = backlinkNotes.map((n) {
          RegExp r = RegExp('\\[\\[$prevTitle\\]\\]', multiLine: true);
          n.content = n.content.replaceAll(r, '[[${updatedNote.title}]]');
          return n;
        }).toList();
        if (await widget.db.updateNotes(updatedBacklinks)) {
          setState(() {
            backlinkNotes = updatedBacklinks;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${backlinkNotes.length} Link(s) Updated'),
            duration: const Duration(seconds: 2),
          ));
        } else {
          errMessage = 'Failed to update backlinks';
        }
      }
    } else {
      titleController.text = prevTitle;
    }
    return errMessage;
  }

  void onChanged() {
    if (widget.note.content != contentController.text ||
        widget.note.title != titleController.text ||
        widget.note.source != sourceController.text) {
      setState(() {
        hasNewChanges = true;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).dialogBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              Header(
                  onSave: (hasNewChanges) ? _saveNote : null,
                  onDelete: _deleteNote,
                  onSearch: () => onSearchNavigate(context)),
              const Divider(thickness: 1, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding:
                      EdgeInsets.all(Theme.of(context).custom.kDefaultPadding),
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
                      ),
                      SizedBox(
                          height: Theme.of(context).custom.kDefaultPadding),
                      const Text("Backlinks", style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      SizedBox(
                          height: Theme.of(context).custom.kDefaultPadding / 2),
                      ...backlinkNotes.map((note) => NoteCard(
                            note: note,
                            onTap: () {
                              widget.db.navigateToNote(note); // TODO: Deprecate
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
    );
  }
}
