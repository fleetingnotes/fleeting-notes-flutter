import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

import 'package:fleeting_notes_flutter/components/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';

import 'package:fleeting_notes_flutter/screens/main/components/note_card.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/screens/note/components/header.dart';
import 'package:fleeting_notes_flutter/constants.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({
    Key? key,
    required this.note,
    required this.db,
  }) : super(key: key);

  final Note note;
  final RealmDB db;
  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  List<Note> backlinkNotes = [];
  bool hasNewChanges = false;
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
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

  void _deleteNote() {
    Note deletedNote = widget.note;
    deletedNote.isDeleted = true;
    widget.db.deleteNote(widget.note);
    widget.db.streamController.add(deletedNote);
    Navigator.pop(context);
  }

  Future<String> _saveNote() async {
    Note updatedNote = widget.note;
    String prevTitle = widget.note.title;
    updatedNote.title = titleController.text;
    updatedNote.content = contentController.text;
    String errMessage = await checkTitle(updatedNote.id, updatedNote.title);
    if (errMessage == '') {
      widget.db.upsertNote(updatedNote);
      widget.db.streamController.add(updatedNote);
      setState(() {
        hasNewChanges = false;
      });
    } else {
      titleController.text = prevTitle;
    }
    return errMessage;
  }

  void _onChanged(text) {
    setState(() {
      hasNewChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Header(
                onSave: (hasNewChanges) ? _saveNote : null,
                onDelete: _deleteNote,
              ),
              const Divider(thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note.getDateTimeStr(),
                        style: Theme.of(context).textTheme.caption,
                      ),
                      TextField(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: "Title",
                          border: InputBorder.none,
                        ),
                        onChanged: _onChanged,
                      ),
                      TextField(
                        autofocus: true,
                        controller: contentController,
                        minLines: 5,
                        maxLines: 10,
                        style: Theme.of(context).textTheme.bodyText2,
                        decoration: const InputDecoration(
                          hintText: "Note",
                          border: InputBorder.none,
                        ),
                        onChanged: _onChanged,
                      ),
                      const SizedBox(height: kDefaultPadding),
                      const Text("Backlinks", style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      const SizedBox(height: kDefaultPadding / 2),
                      ...backlinkNotes.map((note) => NoteCard(
                            note: note,
                            press: () {
                              widget.db.navigateToNote(note);
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
