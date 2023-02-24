import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../utils/responsive.dart';
import 'components/modify_notes_bar.dart';
import 'components/search_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    Key? key,
    this.searchFocusNode,
    this.hasSearchFocus = false,
    // keep track of notes selected
  }) : super(key: key);

  final FocusNode? searchFocusNode;
  final bool hasSearchFocus;

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

  Future<void> loadNotes({forceSync = false}) async {
    final db = ref.read(dbProvider);
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    try {
      var tempNotes = await db.getSearchNotes(
        searchQuery,
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
        ));
      } else {
        rethrow;
      }
    }
  }

  Future<void> _pullRefreshNotes() async {
    await loadNotes(forceSync: true);
  }

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    final sq = ref.read(searchProvider);
    loadNotes();
    db.listenNoteChange((e) => loadNotes()).then((stream) {
      noteChangeStream = stream;
    });
    queryController.text = sq?.query ?? '';
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream?.cancel();
  }

  void _pressNote(BuildContext context, Note note) {
    final noteHistory = ref.read(noteHistoryProvider.notifier);
    final sqNotifier = ref.read(searchProvider.notifier);
    if (selectedNotes.isEmpty) {
      if (Responsive.isMobile(context)) {
        sqNotifier.updateSearch(null);
      }
      noteHistory.addNote(context, note);
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
    final noteUtil = ref.read(noteUtilsProvider);
    try {
      await noteUtil.handleDeleteNote(context, selectedNotes);
      clearNotes();
    } on FleetingNotesException {
      return;
    }
  }

  void addNote() {
    final nh = ref.read(noteHistoryProvider.notifier);
    final db = ref.read(dbProvider);
    db.closeDrawer();
    final note = Note.empty();
    nh.addNote(context, note);
  }

  Widget getSearchList() {
    final searchQuery = ref.read(searchProvider);
    int crossAxisCount = 2;
    if (Responsive.isTablet(context)) {
      crossAxisCount = 3;
    } else if (Responsive.isDesktop(context)) {
      crossAxisCount = 4;
    }
    return NoteGrid(
      notes: notes,
      selectedNotes: selectedNotes,
      searchQuery: searchQuery,
      crossAxisCount: crossAxisCount,
      controller: scrollController,
      onRefresh: _pullRefreshNotes,
      onSelect: _longPressNote,
      onTap: _pressNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    ref.listen<SearchQuery?>(searchProvider, (_, sq) {
      if (sq == null) {
        queryController.text = '';
        searchFocusNode.unfocus();
      } else if (queryController.text != sq.query) {
        queryController.text = sq.query;
      }
      loadNotes();
    });
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: selectedNotes.isEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          onMenu: db.openDrawer,
                          controller: queryController,
                          focusNode: widget.searchFocusNode,
                        ),
                      ),
                      if (!Responsive.isMobile(context))
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: FilledButton(
                            onPressed: addNote,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: const [
                                  Icon(Icons.add),
                                  SizedBox(width: 8),
                                  Text('New note'),
                                ],
                              ),
                            ),
                          ),
                        )
                    ],
                  )
                : ModifyNotesAppBar(
                    selectedNotes: selectedNotes,
                    clearNotes: clearNotes,
                    deleteNotes: deleteNotes,
                  ),
          ),
          Expanded(child: getSearchList()),
        ],
      ),
    );
  }
}

class NoteGrid extends StatelessWidget {
  const NoteGrid({
    super.key,
    required this.notes,
    this.selectedNotes = const [],
    this.searchQuery,
    this.crossAxisCount = 1,
    this.childAspectRatio = 1,
    this.onRefresh,
    this.onSelect,
    this.onTap,
    this.controller,
  });

  final List<Note> notes;
  final List<Note> selectedNotes;
  final SearchQuery? searchQuery;
  final int crossAxisCount;
  final double childAspectRatio;
  final Future<void> Function()? onRefresh;
  final Function(BuildContext, Note)? onSelect;
  final Function(BuildContext, Note)? onTap;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              onRefresh?.call();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey('ListOfNotes'),
              controller: controller,
              itemCount: notes.length,
              itemBuilder: (context, index) => NoteCard(
                sQuery: searchQuery,
                note: notes[index],
                isSelected: selectedNotes.contains(notes[index]),
                onSelect: (onSelect == null)
                    ? null
                    : () => onSelect?.call(context, notes[index]),
                onTap: () => onTap?.call(context, notes[index]),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
