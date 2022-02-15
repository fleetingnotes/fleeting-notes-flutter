import 'package:flutter/material.dart';
import '../../models/Note.dart';

import 'package:fleeting_notes_flutter/screens/main/components/note_card.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/screens/note/components/header.dart';
import '../../constants.dart';

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
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    widget.db.getBacklinkNotes(widget.note).then((notes) {
      setState(() {
        backlinkNotes = notes;
      });
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
                onSave: () {},
                onDelete: () {},
              ),
              const Divider(thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding: EdgeInsets.all(kDefaultPadding),
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
                      ),
                      SizedBox(height: kDefaultPadding),
                      Text("Backlinks", style: TextStyle(fontSize: 12)),
                      Divider(thickness: 1, height: 1),
                      SizedBox(height: kDefaultPadding / 2),
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
