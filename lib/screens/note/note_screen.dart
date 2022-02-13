import 'package:flutter/material.dart';
import '../../models/Note.dart';

import 'package:fleeting_notes_flutter/screens/main/components/note_card.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import '../../constants.dart';

class NoteScreen extends StatelessWidget {
  NoteScreen({
    Key? key,
    required this.note,
    required this.db,
  }) : super(key: key);

  final Note note;
  final RealmDB db;
  final List<Note> backlinkNotes = [
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
    Note(id: '0', title: 'backlink Note', content: 'backlink Note'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(),
              Divider(thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  padding: EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.getDateTimeStr(),
                        style: Theme.of(context).textTheme.caption,
                      ),
                      TextField(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        controller: TextEditingController(text: note.title),
                        decoration: const InputDecoration(
                          hintText: "Title",
                          border: InputBorder.none,
                        ),
                      ),
                      TextField(
                        autofocus: true,
                        controller: TextEditingController(text: note.content),
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
                      Divider(thickness: 1),
                      SizedBox(height: kDefaultPadding / 2),
                      ...backlinkNotes.map((note) => NoteCard(
                            note: note,
                            press: () {
                              db.navigateToNote(note);
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
