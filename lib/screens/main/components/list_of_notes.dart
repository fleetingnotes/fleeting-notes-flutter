import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:flutter/material.dart';

import 'note_card.dart';
import '../../../models/Note.dart';
import '../../../constants.dart';
import '../../../responsive.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ListOfNotes extends StatefulWidget {
  const ListOfNotes({
    Key? key,
    required this.query,
    required this.db,
    required this.openDrawer,
  }) : super(key: key);

  final String query;
  final RealmDB db;
  final VoidCallback? openDrawer;

  @override
  State<ListOfNotes> createState() => _ListOfNotesState();
}

class _ListOfNotesState extends State<ListOfNotes> {
  final ScrollController scrollController = ScrollController();
  late List<Note> notes = [];
  int activeNoteIndex = -1;

  Future<void> loadNotes() async {
    var tempNotes = await widget.db.getNotes();
    setState(() {
      notes = tempNotes;
    });
  }

  void updateNote(Note updatedNote) {
    setState(() {
      if (updatedNote.isDeleted) {
        Note? activeNote =
            (activeNoteIndex >= 0) ? notes[activeNoteIndex] : null;
        notes.removeWhere((note) => note.id == updatedNote.id);
        if (activeNote != null && activeNote.id == updatedNote.id) {
          activeNoteIndex = -1;
        }
      } else {
        bool isUpdated = false;
        notes.asMap().forEach((i, note) {
          if (note.id == updatedNote.id) {
            notes[i] = updatedNote;
            isUpdated = true;
          }
        });
        if (!isUpdated) {
          notes.add(updatedNote);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
    widget.db.listenNoteChange(updateNote);
  }

  void _pressNote(int index) {
    setState(() {
      activeNoteIndex = index;
    });
    widget.db.popAllRoutes();
    widget.db.navigateToNote(notes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: kIsWeb ? kDefaultPadding : 0),
        color: kBgDarkColor,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              // This is our Seearch bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Row(
                  children: [
                    // Once user click the menu icon the menu shows like drawer
                    // Also we want to hide this menu icon on desktop
                    if (!Responsive.isDesktop(context))
                      IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: widget.openDrawer,
                      ),
                    if (!Responsive.isDesktop(context)) SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {},
                        decoration: InputDecoration(
                          hintText: 'Search',
                          fillColor: kBgLightColor,
                          filled: true,
                          suffixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: kDefaultPadding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Row(
                  children: [
                    Icon(Icons.arrow_drop_down, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "Sort by date",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    MaterialButton(
                      minWidth: 20,
                      onPressed: () {},
                      child: Icon(Icons.sort, size: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: kDefaultPadding),
              Expanded(
                child: ListView.builder(
                  key: PageStorageKey('ListOfNotes'),
                  controller: scrollController,
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(
                    note: notes[index],
                    isActive: Responsive.isMobile(context)
                        ? false
                        : index == activeNoteIndex,
                    press: () {
                      _pressNote(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
