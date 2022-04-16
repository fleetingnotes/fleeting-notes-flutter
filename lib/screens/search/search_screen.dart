import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter/material.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../responsive.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../note/components/note_editor.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    Key? key,
    required this.db,
  }) : super(key: key);

  final Database db;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController queryController = TextEditingController();
  late List<Note> notes = [];
  String sortBy = 'Sort by date (new to old)';
  Map<String, SortOptions> sortOptionMap = {
    'Sort by date (new to old)': SortOptions.dateASC,
    'Sort by date (old to new)': SortOptions.dateDESC,
    'Sort by title (A to Z)': SortOptions.titleASC,
    'Sort by title (Z to A)': SortOptions.titleDSC,
    'Sort by content (A to Z)': SortOptions.contentASC,
    'Sort by content (Z to A)': SortOptions.contentDESC,
    'Sort by source (A to Z)': SortOptions.sourceASC,
    'Sort by source (Z to A)': SortOptions.sourceDESC,
  };
  String activeNoteId = '';
  Map searchFilter = {'title': true, 'content': true, 'source': true};

  Future<void> loadNotes(queryRegex, {forceSync = false}) async {
    if (!mounted) return;
    SearchQuery query = SearchQuery(
        queryRegex: queryRegex,
        searchByTitle: searchFilter['title'],
        searchByContent: searchFilter['content'],
        searchBySource: searchFilter['source'],
        sortBy: sortOptionMap[sortBy]!);
    var tempNotes = await widget.db.getSearchNotes(
      query,
      forceSync: forceSync,
    );
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
    loadNotes(queryController.text, forceSync: true);
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
        padding: EdgeInsets.only(
            top: kIsWeb ? Theme.of(context).custom.kDefaultPadding : 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              // This is our Seearch bar
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Theme.of(context).custom.kDefaultPadding,
                    vertical: Theme.of(context).custom.kDefaultPadding / 2),
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
                          fillColor: Theme.of(context).dialogBackgroundColor,
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
              SizedBox(height: Theme.of(context).custom.kDefaultPadding),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Theme.of(context).custom.kDefaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: sortBy,
                            iconSize: 16,
                            style: Theme.of(context).textTheme.bodyText1,
                            onChanged: (String? newValue) {
                              setState(() {
                                sortBy = newValue!;
                              });
                              loadNotes(queryController.text);
                            },
                            items: sortOptionMap.keys
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Search by',
                      child: MaterialButton(
                        minWidth: 20,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return SearchDialog(
                                searchFilter: searchFilter,
                                onFilterChange: (type, val) {
                                  setState(() {
                                    searchFilter[type] = val;
                                  });
                                  loadNotes(queryController.text);
                                },
                              );
                            },
                          );
                        },
                        child: const Icon(Icons.filter_list, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Theme.of(context).custom.kDefaultPadding),
              Expanded(
                child: ListView.builder(
                  key: const PageStorageKey('ListOfNotes'),
                  controller: scrollController,
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(
                    sQuery: SearchQuery(
                        queryRegex: queryController.text,
                        searchByTitle: searchFilter['title'],
                        searchByContent: searchFilter['content'],
                        searchBySource: searchFilter['source'],
                        sortBy: sortOptionMap[sortBy]!),
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

  final Database db;

  @override
  Widget build(BuildContext context) {
    var history = db.noteHistory.entries.toList();
    db.navigatorKey = GlobalKey<NavigatorState>();
    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
          settings: route,
          pageBuilder: (context, _, __) {
            if (history.isEmpty || history.first.key.isEmpty()) {
              return SearchScreen(
                key: db.searchKey,
                db: db,
              );
            } else {
              return NoteEditor(
                key: history.first.value,
                note: history.first.key,
                db: db,
                isShared: true,
              );
            }
          }),
    );
  }
}
