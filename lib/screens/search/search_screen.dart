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
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController queryController = TextEditingController();
  late List<Note> notes = [];
  String activeNoteId = '';

  Future<void> loadNotes(queryRegex) async {
    var tempNotes = await widget.db.getSearchNotes(queryRegex);
    setState(() {
      notes = tempNotes;
    });
  }

  void listenCallback(event) {
    loadNotes(queryController.text);
  }

  @override
  void initState() {
    super.initState();
    loadNotes(queryController.text);
    widget.db.listenNoteChange(listenCallback);
  }

  void _pressNote(BuildContext context, Note note) {
    setState(() {
      activeNoteId = note.id;
    });
    if (!Responsive.isMobile(context)) {
      widget.db.popAllRoutes();
    }
    widget.db.navigateToNote(note);
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
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: widget.db.openDrawer,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        controller: queryController,
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
                        : notes[index].id == activeNoteId,
                    onTap: () {
                      _pressNote(context, notes[index]);
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

class SearchScreenNavigator extends StatelessWidget {
  const SearchScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    db.navigatorKey = GlobalKey<NavigatorState>();
    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) => SearchScreen(
          key: db.searchKey,
          db: db,
        ),
      ),
    );
  }
}
