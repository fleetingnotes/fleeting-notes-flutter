import 'package:flutter/material.dart';

import 'note_card.dart';
import '../../../models/Note.dart';
import '../../../constants.dart';
import '../../../responsive.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ListOfNotes extends StatefulWidget {
  const ListOfNotes(
      {Key? key,
      required this.query,
      required this.visible,
      required this.getNotes})
      : super(key: key);

  final String query;
  final bool visible;
  final Function getNotes;

  @override
  State<ListOfNotes> createState() => _ListOfNotesState();
}

class _ListOfNotesState extends State<ListOfNotes> {
  final ScrollController scrollController = ScrollController();
  late List<Note> notes = [];

  Future<void> loadNotes() async {
    var tempNotes = await widget.getNotes();
    setState(() {
      notes = tempNotes;
    });
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey,
      drawer: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 250),
        child: Text('hello from drawer'),
      ),
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
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
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
                  itemCount: notes.length,
                  itemBuilder: (context, index) =>
                      NoteCard(note: notes[index], isActive: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
