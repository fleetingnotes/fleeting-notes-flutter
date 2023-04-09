import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    this.addNote,
    this.recordNote,
    // keep track of notes selected
  }) : super(key: key);

  final FocusNode? searchFocusNode;
  final bool hasSearchFocus;
  final VoidCallback? addNote;
  final VoidCallback? recordNote;

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
    searchQuery.limit = null;
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
    if (selectedNotes.isEmpty) {
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

  Widget getSearchList() {
    final searchQuery = ref.read(searchProvider);
    final settings = ref.read(settingsProvider);
    int crossAxisCount = 2;
    if (Responsive.isTablet(context)) {
      crossAxisCount = 3;
    } else if (Responsive.isDesktop(context)) {
      crossAxisCount = 4;
    }

    return ValueListenableBuilder(
      valueListenable: settings.box.listenable(keys: ['search-is-list-view']),
      builder: (context, _, __) {
        bool isListView =
            settings.get('search-is-list-view', defaultValue: false) ?? false;
        return NoteGrid(
          notes: notes,
          maxLines: 12,
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
          selectedNotes: selectedNotes,
          searchQuery: searchQuery,
          crossAxisCount: (isListView) ? 1 : crossAxisCount,
          controller: scrollController,
          onRefresh: _pullRefreshNotes,
          onSelect: _longPressNote,
          onTap: _pressNote,
        );
      },
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: selectedNotes.isEmpty
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SearchBar(
                          onMenu: db.openDrawer,
                          controller: queryController,
                          focusNode: widget.searchFocusNode,
                        ),
                      ),
                    ),
                    if (widget.addNote != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton(
                          onPressed: widget.addNote,
                          onLongPress: widget.recordNote,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
    this.childAspectRatio,
    this.maxLines,
    this.padding,
    this.onRefresh,
    this.onSelect,
    this.onTap,
    this.controller,
  });

  final List<Note> notes;
  final List<Note> selectedNotes;
  final SearchQuery? searchQuery;
  final int crossAxisCount;
  final double? childAspectRatio;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;
  final Function(BuildContext, Note)? onSelect;
  final Function(BuildContext, Note)? onTap;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: (crossAxisCount == 1 && childAspectRatio == null)
          ? ListView.builder(
              key: const PageStorageKey('ListOfNotes'),
              padding: padding,
              controller: controller,
              itemCount: notes.length,
              shrinkWrap: true,
              itemBuilder: (context, index) => NoteCard(
                sQuery: searchQuery,
                note: notes[index],
                isSelected: selectedNotes.contains(notes[index]),
                onSelect: (onSelect == null)
                    ? null
                    : () => onSelect?.call(context, notes[index]),
                onTap: () => onTap?.call(context, notes[index]),
                maxLines: maxLines,
              ),
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey('ListOfNotes'),
              padding: padding,
              controller: controller,
              itemCount: notes.length,
              itemBuilder: (context, index) => NoteCard(
                sQuery: searchQuery,
                note: notes[index],
                expanded: true,
                isSelected: selectedNotes.contains(notes[index]),
                onSelect: (onSelect == null)
                    ? null
                    : () => onSelect?.call(context, notes[index]),
                onTap: () => onTap?.call(context, notes[index]),
                maxLines: maxLines,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio ?? 1,
              ),
            ),
    );
  }
}
