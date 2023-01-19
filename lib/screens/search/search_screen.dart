import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.child,
    this.hasSearchFocus = false,
    // keep track of notes selected
  }) : super(key: key);

  final FocusNode? searchFocusNode;
  final Widget? child;
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
  String activeNoteId = '';

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
    loadNotes();
    db.listenNoteChange((e) => loadNotes()).then((stream) {
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
    final noteUtils = ref.read(noteUtilsProvider);
    if (selectedNotes.isEmpty) {
      setState(() {
        activeNoteId = note.id;
      });
      if (!Responsive.isMobile(context)) {
        db.popAllRoutes();
      }
      noteUtils.openNoteEditorDialog(context, note);
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
    return SafeArea(
      right: true,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _pullRefreshNotes,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                key: const PageStorageKey('ListOfNotes'),
                controller: scrollController,
                itemCount: notes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) => NoteCard(
                  sQuery: searchQuery,
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
    Widget? child = widget.child;
    return Scaffold(
      appBar: selectedNotes.isNotEmpty
          ? PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: ModifyNotesAppBar(
                selectedNotes: selectedNotes,
                clearNotes: clearNotes,
                deleteNotes: deleteNotes,
              ))
          : PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: SearchBar(
                onMenu: db.openDrawer,
                controller: queryController,
                focusNode: widget.searchFocusNode,
              ),
            ),
      body: (child == null) ? getSearchList() : child,
    );
  }
}
