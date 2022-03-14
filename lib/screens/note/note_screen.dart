@JS()
library main;

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'dart:js_util';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:fleeting_notes_flutter/constants.dart';

@JS('chrome.tabs.query')
external dynamic queryTabs(dynamic queryInfo);

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
  bool sourceFieldVisible = false;

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
    setState(() {
      sourceFieldVisible = widget.note.source.isNotEmpty || !kIsWeb;
    });
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

  Future<String> getSourceUrl({String defaultText = ''}) async {
    try {
      var queryOptions = jsify({'active': true, 'currentWindow': true});
      dynamic tabs = await promiseToFuture(queryTabs(queryOptions));
      return getProperty(tabs[0], 'url');
    } catch (e) {
      print(e);
      return defaultText;
    }
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
    updatedNote.source = sourceController.text;
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

  void launchURLBrowser(String url) async {
    void _failUrlSnackbar(String message) {
      var snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Uri? uri = Uri.tryParse(url);
    String newUrl = '';
    if (uri == null) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
      return;
    }
    newUrl =
        (uri.scheme.isEmpty) ? 'https://' + uri.toString() : uri.toString();

    if (await canLaunch(newUrl)) {
      await launch(newUrl);
    } else {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
    }
  }

  void onChanged() {
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
                      TitleField(controller: titleController),
                      ContentField(
                        controller: contentController,
                        db: widget.db,
                        onChanged: onChanged,
                      ),
                      (sourceFieldVisible)
                          ? TextField(
                              style: Theme.of(context).textTheme.bodyText2,
                              controller: sourceController,
                              decoration: InputDecoration(
                                hintText: "Source",
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  tooltip: 'Open URL',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () =>
                                      launchURLBrowser(sourceController.text),
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () async {
                                sourceController.text = await getSourceUrl(
                                    defaultText: sourceController.text);
                                setState(() {
                                  sourceFieldVisible = true;
                                  hasNewChanges = true;
                                });
                              },
                              child: const Text('Add Source URL'),
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

class NoteScreenNavigator extends StatelessWidget {
  NoteScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) => NoteScreen(
          note: Note.empty(),
          db: db,
        ),
      ),
    );
  }
}
