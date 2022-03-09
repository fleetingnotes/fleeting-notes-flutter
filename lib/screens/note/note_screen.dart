import 'package:fleeting_notes_flutter/screens/note/components/title_links.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fleeting_notes_flutter/models/Note.dart';

import 'package:fleeting_notes_flutter/components/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definition.dart';
import 'package:fleeting_notes_flutter/models/text_part_style_definitions.dart';

import 'package:fleeting_notes_flutter/components/note_card.dart';
import 'package:fleeting_notes_flutter/screens/note/components/follow_link.dart';
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
  final LayerLink layerLink = LayerLink();
  bool titleLinksVisible = false;
  final ValueNotifier<String> titleLinkQuery = ValueNotifier('');
  final FocusNode contentFocusNode = FocusNode();
  late OverlayEntry overlayEntry = OverlayEntry(
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
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

  void showTitleLinksOverlay(context, BoxConstraints size) {
    Offset caretOffset = getCaretOffset(
      contentController,
      Theme.of(context).textTheme.bodyText2!,
      size,
    );

    Widget builder(context) {
      return Container(
        child: ValueListenableBuilder(
            valueListenable: titleLinkQuery,
            builder: (context, value, child) {
              return TitleLinks(
                caretOffset: caretOffset,
                titles: ['hello', 'world', 'how', 'areo', 'you'],
                query: titleLinkQuery.value,
                onLinkSelect: (String link) {
                  String t = contentController.text;
                  int caretI = contentController.selection.baseOffset;
                  String beforeCaretText = t.substring(0, caretI);
                  int linkIndex = beforeCaretText.lastIndexOf('[[');
                  contentController.text = t.substring(0, linkIndex) +
                      '[[$link]]' +
                      t.substring(caretI, t.length);
                  contentController.selection = TextSelection.fromPosition(
                      TextPosition(offset: linkIndex + link.length + 4));
                  titleLinkQuery.value = '';
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                },
                layerLink: layerLink,
              );
            }),
      );
    }

    overlayContent(builder);
  }

  Offset getCaretOffset(TextEditingController textController,
      TextStyle textStyle, BoxConstraints size) {
    String beforeCaretText =
        textController.text.substring(0, textController.selection.baseOffset);

    TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: textStyle,
        text: beforeCaretText,
      ),
    );
    painter.layout(maxWidth: size.maxWidth);

    return Offset(
      painter.computeLineMetrics().last.width,
      painter.height + 10,
    );
  }

  void overlayContent(builder) {
    OverlayState? overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(builder: builder);
    // show overlay
    if (overlayState != null) {
      overlayState.insert(overlayEntry);
    }
  }

  void showFollowLinkOverlay(context, BoxConstraints size) async {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }

    // check if caretOffset is in a link
    var caretIndex = contentController.selection.baseOffset;
    var matches = RegExp(Note.linkRegex).allMatches(contentController.text);
    Iterable<dynamic> filteredMatches =
        matches.where((m) => m.start < caretIndex && m.end > caretIndex);

    if (filteredMatches.isNotEmpty) {
      String title = filteredMatches.first.group(1);

      void _onTap() async {
        Note? note = await widget.db.getNoteByTitle(title);
        note ??= Note.empty(title: title);
        widget.db.navigateToNote(note);
      }

      // init overlay entry
      Offset caretOffset = getCaretOffset(
        contentController,
        Theme.of(context).textTheme.bodyText2!,
        size,
      );
      FollowLink builder(context) {
        return FollowLink(
          caretOffset: caretOffset,
          onTap: _onTap,
          layerLink: layerLink,
        );
      }

      overlayContent(builder);
    }
  }

  bool isTitleLinksVisible(text) {
    int i = text.lastIndexOf('[[');
    if (i == -1) return false;
    return !text.substring(i, text.length).contains(']');
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
                        onChanged: (text) {
                          setState(() {
                            hasNewChanges = true;
                          });
                        },
                      ),
                      CompositedTransformTarget(
                        link: layerLink,
                        child: LayoutBuilder(builder: (context, size) {
                          return TextField(
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
                            onChanged: (text) {
                              setState(() {
                                hasNewChanges = true;
                              });
                              var caretIndex =
                                  contentController.selection.baseOffset;
                              String beforeCaretText = text.substring(
                                  0, contentController.selection.baseOffset);

                              bool isVisible = isTitleLinksVisible(
                                  beforeCaretText.substring(0, caretIndex));

                              if (isVisible) {
                                if (!titleLinksVisible) {
                                  showTitleLinksOverlay(context, size);
                                  titleLinksVisible = true;
                                } else {
                                  String query = beforeCaretText.substring(
                                      beforeCaretText.lastIndexOf('[[') + 2,
                                      beforeCaretText.length);
                                  titleLinkQuery.value = query;
                                }
                              } else {
                                titleLinksVisible = false;
                                if (overlayEntry.mounted) {
                                  overlayEntry.remove();
                                }
                              }
                            },
                            onTap: () => showFollowLinkOverlay(context, size),
                          );
                        }),
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
