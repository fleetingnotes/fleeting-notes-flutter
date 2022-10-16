import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:flutter/material.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../utils/responsive.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../note/note_editor.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    Key? key,
    required this.db,
    this.searchFocusNode,
    // keep track of notes selected
  }) : super(key: key);

  final Database db;
  final FocusNode? searchFocusNode;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final StreamSubscription noteChangeStream;
  final ScrollController scrollController = ScrollController();
  final TextEditingController queryController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  var selectedNotes = <Note>[];

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
    SearchQuery query = SearchQuery(
        query: queryRegex,
        searchByTitle: searchFilter['title'],
        searchByContent: searchFilter['content'],
        searchBySource: searchFilter['source'],
        sortBy: sortOptionMap[sortBy]!);
    try {
      var tempNotes = await widget.db.getSearchNotes(
        query,
        forceSync: forceSync,
      );
      if (!mounted) return;
      setState(() {
        notes = tempNotes;
      });
    } catch (e) {
      if (e is FleetingNotesException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 2),
        ));
      } else if (e is FirebaseException &&
          e.code == 'cloud_firestore/permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication failed, try logging in again'),
          duration: Duration(seconds: 2),
        ));
      } else {
        rethrow;
      }
    }
  }

  void listenCallback(event) {
    loadNotes(queryController.text);
  }

  void listenCallbackForceSync(event) {
    loadNotes(queryController.text, forceSync: true);
  }

  @override
  void initState() {
    super.initState();
    setInitSearchQuery();
    loadNotes(queryController.text);
    widget.db.listenNoteChange(listenCallback).then((stream) {
      noteChangeStream = stream;
    });
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream.cancel();
  }

  void _pressNote(BuildContext context, Note note) {
    if (selectedNotes.isEmpty) {
      setState(() {
        activeNoteId = note.id;
      });
      if (!Responsive.isMobile(context)) {
        widget.db.popAllRoutes();
      }
      widget.db.navigateToNote(note);
    } else {
      setState(() {
        if (selectedNotes.contains(note)) {
          selectedNotes.remove(note);
        } else {
          selectedNotes.add(note);
        }
      });
    }
  }

  void _longPressNote(BuildContext context, Note note) async {
    if (selectedNotes.contains(note)) {
      setState(() {
        selectedNotes.remove(note);
      });
    } else {
      setState(() {
        selectedNotes.add(note);
      });
    }
  }

  void clearNotes() {
    setState(() {
      selectedNotes = [];
    });
  }

  void deleteNotes(BuildContext context) async {
    for (var note in selectedNotes) {
      note.isDeleted = true;
      // only do if mobile app
      bool isSuccessDelete = await widget.db.deleteNote(note);
      if (isSuccessDelete) {
        widget.db.noteHistory.remove(note);
        clearNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notes deletion failed'),
          duration: Duration(seconds: 2),
        ));
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Notes successfully deleted'),
      duration: Duration(seconds: 2),
    ));
  }

  void setInitSearchQuery() async {
    var url = await BrowserExtension().getSourceUrl();
    if (url == '') {
      return;
    }
    //parse to only get base url
    var uri = Uri.parse(url);
    queryController.text = uri.origin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedNotes.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: ModifyNotesAppBar(
                selectedNotes: selectedNotes,
                clearNotes: clearNotes,
                deleteNotes: deleteNotes,
              ))
          : null,
      body: Container(
        padding: EdgeInsets.only(
            top: kIsWeb ? Theme.of(context).custom.kDefaultPadding : 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              // This is our Search bar
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
                        focusNode: widget.searchFocusNode,
                        controller: queryController,
                        onChanged: loadNotes,
                        onTap: () {},
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
                        constraints: const BoxConstraints(maxWidth: 180),
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
                        query: queryController.text,
                        searchByTitle: searchFilter['title'],
                        searchByContent: searchFilter['content'],
                        searchBySource: searchFilter['source'],
                        sortBy: sortOptionMap[sortBy]!),
                    note: notes[index],
                    isActive: Responsive.isMobile(context)
                        ? false
                        : notes[index].id == activeNoteId,
                    isSelected: selectedNotes.contains(notes[index]),
                    onLongPress: () {
                      _longPressNote(context, notes[index]);
                    },
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

class ModifyNotesAppBar extends StatelessWidget {
  const ModifyNotesAppBar({
    Key? key,
    required this.selectedNotes,
    required this.clearNotes,
    required this.deleteNotes,
  }) : super(key: key);

  final List<Note> selectedNotes;
  final Function() clearNotes;
  final Function(BuildContext) deleteNotes;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: clearNotes,
      ),
      title: Text('${selectedNotes.length} notes selected'),
      actions: <Widget>[
        // action button
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => deleteNotes(context),
        )
      ],
    );
  }
}

class SearchScreenNavigator extends StatelessWidget {
  const SearchScreenNavigator({
    Key? key,
    required this.db,
    this.hasInitNote = false,
  }) : super(key: key);

  final Database db;
  final bool hasInitNote;

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
                isShared: hasInitNote,
              );
            }
          }),
    );
  }
}
