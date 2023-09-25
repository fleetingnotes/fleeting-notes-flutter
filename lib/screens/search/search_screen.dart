import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/screens/search/components/search_bar.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/pinned_notes_manager.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../utils/responsive.dart';
import 'components/modify_notes_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen(
      {Key? key,
      this.searchFocusNode,
      this.hasSearchFocus = false,
      this.addNote,
      this.recordNote,
      this.scrollController,
      this.deletedNotesMode = false
      // keep track of notes selected
      })
      : super(key: key);

  final FocusNode? searchFocusNode;
  final bool hasSearchFocus;
  final VoidCallback? addNote;
  final VoidCallback? recordNote;
  final ScrollController? scrollController;
  final bool deletedNotesMode;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  StreamSubscription? noteChangeStream;
  ScrollController scrollController = ScrollController();
  final TextEditingController queryController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  var selectedNotes = <Note>[];

  late List<Note> notes = [];
  late List<Note> pinnedNotes = [];

  late PinnedNotesManager pinnedNotesManager;

  Future<void> loadNotes({forceSync = false}) async {
    final db = ref.read(dbProvider);
    final List<String> pinnedNotesIds = pinnedNotesManager.getPinnedNotes();
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    searchQuery.limit = null;
    try {
      List<Note> tempPinnedNotes = [];

      if (pinnedNotesIds.isNotEmpty) {
        Iterable<Note?> notes = await db.getNotesByIds(pinnedNotesIds);
        tempPinnedNotes =
            notes.where((note) => note != null).cast<Note>().toList();
      }
      var tempNotes = await db.getSearchNotes(searchQuery,
          forceSync: forceSync,
          filterDeletedNotes: widget.deletedNotesMode,
          excludedIds: pinnedNotesIds);
      if (!mounted) return;
      setState(() {
        notes = tempNotes;
        pinnedNotes = tempPinnedNotes;
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
    final noteUtils = ref.read(noteUtilsProvider);
    pinnedNotesManager = PinnedNotesManager(db.settings);

    scrollController = widget.scrollController ?? scrollController;
    // refresh unsaved note
    noteUtils.setUnsavedNote(context, null, saveUnsaved: true);
    loadNotes();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      noteChangeStream?.cancel();
      db.listenNoteChange((e) => loadNotes()).then((stream) {
        noteChangeStream = stream;
      });
    });
    queryController.text = sq?.query ?? '';
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream?.cancel();
  }

  void showRestoreConfirmation(BuildContext context, Function onRestore) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RestoreNoteModal(
          onRestore: onRestore,
        );
      },
    );
  }

  void _pressNote(BuildContext context, Note note) {
    if (widget.deletedNotesMode) {
      final noteUtil = ref.read(noteUtilsProvider);
      showRestoreConfirmation(context, () async {
        noteUtil.handleRestoreNote(context, [note]);
      });
    } else {
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
      List<String> pinnedNotesWithoutSelectedNotesIds = pinnedNotes
          .where((pinnedNote) => !selectedNotes
              .any((selectedNote) => selectedNote.id == pinnedNote.id))
          .map((pinnedNote) => pinnedNote.id)
          .toList();
      pinnedNotesManager.updatePinnedNotes(pinnedNotesWithoutSelectedNotesIds);
      clearNotes();
    } on FleetingNotesException {
      return;
    }
  }

  void onToggleNotesPinned() async {
    for (var note in selectedNotes) {
      pinnedNotesManager.toggleNotePinned(note.id);
    }
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateSearch(searchQuery.copyWith(
      query: "",
    ));
  }

  Widget getSearchList(List<Note> notes) {
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
          onSelect: widget.deletedNotesMode ? null : _longPressNote,
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: selectedNotes.isEmpty
                ? Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: CustomSearchBar(
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
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
                    onToggleNotesPinned: onToggleNotesPinned),
          ),
        ),
        if (pinnedNotes.isNotEmpty)
          const SliverToBoxAdapter(
            child: CustomTitleRow(title: "PINNED"),
          ),
        if (pinnedNotes.isNotEmpty)
          SliverList(
            delegate: SliverChildListDelegate(
              [
                getSearchList(pinnedNotes),
              ],
            ),
          ),
        if (pinnedNotes.isNotEmpty && notes.isNotEmpty)
          const SliverToBoxAdapter(
            child: CustomTitleRow(title: "OTHERS"),
          ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              getSearchList(notes),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomTitleRow extends StatelessWidget {
  final String title;

  const CustomTitleRow({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class NoteGrid extends StatelessWidget {
  const NoteGrid(
      {super.key,
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
      this.controller});

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
              physics: const NeverScrollableScrollPhysics(),
              // shrinkWrap: true,
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
              physics: const NeverScrollableScrollPhysics(),
              key: const PageStorageKey('ListOfNotes'),
              padding: padding,
              shrinkWrap: true,
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

class RestoreNoteModal extends StatelessWidget {
  final Function onRestore;

  const RestoreNoteModal({super.key, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restore Note'),
      content: const Text('Are you sure you want to restore this note?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onRestore(); // Call the restore function passed in
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
