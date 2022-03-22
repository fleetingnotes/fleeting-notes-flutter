import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

import 'package:fleeting_notes_flutter/components/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';

import 'package:fleeting_notes_flutter/components/note_card.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/screens/note/components/header.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/content_field.dart';
import 'package:fleeting_notes_flutter/screens/note/components/source_container.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/screens/note/components/source_container_web.dart';
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
  bool hasNewChanges = true;
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController sourceController;

  @override
  void initState() {
    super.initState();
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

  void _deleteNote() {
    Note deletedNote = widget.note;
    deletedNote.isDeleted = true;
    widget.db.deleteNote(widget.note);
    Navigator.pop(context);
    widget.db.noteHistory.remove(widget.note);
  }

  Future<String> _saveNote() async {
    Note updatedNote = widget.note;
    String prevTitle = widget.note.title;
    updatedNote.title = titleController.text;
    updatedNote.content = contentController.text;
    updatedNote.source = sourceController.text;
    String errMessage = await checkTitle(updatedNote.id, updatedNote.title);
    if (errMessage == '') {
      widget.db.upsertNote(updatedNote);
      setState(() {
        hasNewChanges = false;
      });
    } else {
      titleController.text = prevTitle;
    }
    return errMessage;
  }

  void onChanged() {
    setState(() {
      hasNewChanges = true;
    });
  }

  void onSearchNavigate(BuildContext context) {
    widget.db.popAllRoutes();
    widget.db.navigateToSearch('');
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
                  onSearch: () => onSearchNavigate(context)),
              const Divider(thickness: 1, height: 1),
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
                      TitleField(
                        controller: titleController,
                        onChanged: onChanged,
                      ),
                      ContentField(
                        controller: contentController,
                        db: widget.db,
                        onChanged: onChanged,
                      ),
                      SourceContainer(
                        controller: sourceController,
                        onChanged: onChanged,
                      ),
                      const SizedBox(height: kDefaultPadding),
                      const Text("Backlinks", style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      const SizedBox(height: kDefaultPadding / 2),
                      ...backlinkNotes.map((note) => NoteCard(
                            note: note,
                            onTap: () {
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

class NoteScreenNavigator extends StatelessWidget {
  const NoteScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    db.navigatorKey = GlobalKey<NavigatorState>();
    var history = db.noteHistory.entries.toList();

    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) {
          if (history.isEmpty) return Container();
          return NoteScreen(
            key: history.last.value,
            note: history.last.key,
            db: db,
          );
        },
      ),
    );
  }
}
