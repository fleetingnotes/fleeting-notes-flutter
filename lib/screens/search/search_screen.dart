import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:flutter/material.dart';

import '../../components/note_card.dart';
import '../../models/Note.dart';
import '../../constants.dart';
import '../../responsive.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    Key? key,
    required this.query,
    required this.db,
    required this.openDrawer,
  }) : super(key: key);

  final String query;
  final RealmDB db;
  final VoidCallback? openDrawer;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController scrollController = ScrollController();
  late List<Note> notes = [];
  int activeNoteIndex = -1;

  Future<void> loadNotes(queryRegex) async {
    var tempNotes = await widget.db.getSearchNotes(queryRegex);
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
          notes.insert(0, updatedNote);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadNotes('');
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
        padding: const EdgeInsets.only(top: kIsWeb ? kDefaultPadding : 0),
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
                        icon: const Icon(Icons.menu),
                        onPressed: widget.openDrawer,
                      ),
                    if (!Responsive.isDesktop(context))
                      const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        onChanged: loadNotes,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          fillColor: kBgLightColor,
                          filled: true,
                          suffixIcon: const Icon(Icons.search),
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
              const SizedBox(height: kDefaultPadding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_drop_down, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "Sort by date",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                    MaterialButton(
                      minWidth: 20,
                      onPressed: null,
                      child: Icon(Icons.sort, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey('ListOfNotes'),
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
