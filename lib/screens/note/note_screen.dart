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
  final FocusNode contentFocusNode = FocusNode();
  final GlobalKey _scaffoldKey = GlobalKey();
  late OverlayEntry overlayFollowLinkEntry = OverlayEntry(
    builder: (context) => Container(),
  );

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
    contentFocusNode.addListener(() {
      if (overlayFollowLinkEntry.mounted) {
        overlayFollowLinkEntry.remove();
      }
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

  Offset getScaffoldOffset(GlobalKey key) {
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    return offset;
  }

  Offset getCaretPositionTextField(TextEditingController textController,
      TextStyle textStyle, FocusNode focusNode) {
    String beforeCaretText =
        textController.text.substring(0, textController.selection.baseOffset);

    TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: textStyle,
        text: beforeCaretText,
      ),
    );
    painter.layout();

    return Offset(
      focusNode.offset.dx + painter.width,
      focusNode.offset.dy + painter.height,
    );
  }

  void showFollowLinkOverlay(context) async {
    if (overlayFollowLinkEntry.mounted) {
      overlayFollowLinkEntry.remove();
    }

    // check if caretOffset is in a link
    var caretOffset = contentController.selection.baseOffset;
    var matches = RegExp(Note.linkRegex).allMatches(contentController.text);
    Iterable<dynamic> filteredMatches =
        matches.where((m) => m.start < caretOffset && m.end > caretOffset);

    if (filteredMatches.isNotEmpty) {
      String title = filteredMatches.first.group(1);

      void _onTap() async {
        Note? note = await widget.db.getNoteByTitle(title);
        note ??= Note.empty(title: title);
        widget.db.navigateToNote(note);
      }

      // init overlay entry
      OverlayState? overlayState = Overlay.of(context);
      Offset caretPosition = getCaretPositionTextField(
        contentController,
        Theme.of(context).textTheme.bodyText2!,
        contentFocusNode,
      );
      Offset scaffoldOffset = getScaffoldOffset(_scaffoldKey);
      overlayFollowLinkEntry = OverlayEntry(builder: (context) {
        return FollowLink(
            caretPosition: caretPosition - scaffoldOffset, onTap: _onTap);
      });

      // show overlay
      if (overlayState != null) {
        overlayState.insert(overlayFollowLinkEntry);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                        focusNode: contentFocusNode,
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
                        onTap: () => showFollowLinkOverlay(context),
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

class FollowLink extends StatelessWidget {
  const FollowLink({
    Key? key,
    required this.caretPosition,
    required this.onTap,
  }) : super(key: key);

  final Offset caretPosition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Decides where to place FollowLink on the screen.
      top: caretPosition.dy,
      left: caretPosition.dx,

      // Tag code.
      child: OutlinedButton(
          onPressed: onTap,
          child: Text(
            'Follow Link',
            style: TextStyle(
              fontSize: 15,
            ),
          )),
    );
  }
}
