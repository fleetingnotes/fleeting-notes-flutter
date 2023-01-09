import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../utils/responsive.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import '../note/note_editor.dart';
import 'components/search_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    Key? key,
    this.searchFocusNode,
    // keep track of notes selected
  }) : super(key: key);

  final FocusNode? searchFocusNode;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  StreamSubscription? noteChangeStream;
  final ScrollController scrollController = ScrollController();
  final TextEditingController queryController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  var selectedNotes = <Note>[];

  late List<Note> notes = [];
  String sortBy = 'Sort by created (new to old)';
  Map<String, SortOptions> sortOptionMap = {
    'Sort by modified (new to old)': SortOptions.modifiedASC,
    'Sort by modified (old to new)': SortOptions.modifiedDESC,
    'Sort by created (new to old)': SortOptions.createdASC,
    'Sort by created (old to new)': SortOptions.createdDESC,
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
    final db = ref.read(dbProvider);
    SearchQuery query = SearchQuery(
        query: queryRegex,
        searchByTitle: searchFilter['title'],
        searchByContent: searchFilter['content'],
        searchBySource: searchFilter['source'],
        sortBy: sortOptionMap[sortBy]!);
    try {
      var tempNotes = await db.getSearchNotes(
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
      } else {
        rethrow;
      }
    }
  }

  void listenCallback(event) {
    loadNotes(queryController.text);
  }

  Future<void> _pullRefreshNotes() async {
    await loadNotes(queryController.text, forceSync: true);
  }

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    loadNotes(queryController.text);
    db.listenNoteChange(listenCallback).then((stream) {
      noteChangeStream = stream;
    });
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream?.cancel();
  }

  void _pressNote(BuildContext context, Note note) {
    final db = ref.read(dbProvider);
    if (selectedNotes.isEmpty) {
      setState(() {
        activeNoteId = note.id;
      });
      if (!Responsive.isMobile(context)) {
        db.popAllRoutes();
      }
      db.navigateToNote(note);
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
    final db = ref.read(dbProvider);
    bool isSuccessDelete = await db.deleteNotes(selectedNotes);
    if (isSuccessDelete) {
      for (var note in selectedNotes) {
        db.noteHistory.remove(note);
      }
      clearNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notes deletion failed'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Notes successfully deleted'),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
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
      body: SafeArea(
        right: false,
        child: Column(
          children: [
            // This is our Search bar
            SearchBar(
              onMenuPressed: db.openDrawer,
              controller: queryController,
              focusNode: widget.searchFocusNode,
              onChanged: loadNotes,
              onTap: () {},
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
                      constraints: const BoxConstraints(maxWidth: 200),
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
              child: RefreshIndicator(
                onRefresh: _pullRefreshNotes,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
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

class SearchScreenNavigator extends ConsumerWidget {
  const SearchScreenNavigator({
    Key? key,
    this.hasInitNote = false,
  }) : super(key: key);

  final bool hasInitNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
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
              );
            } else {
              return NoteEditor(
                key: history.first.value,
                note: history.first.key,
                isShared: hasInitNote,
              );
            }
          }),
    );
  }
}
