import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/search_query.dart';
import '../../widgets/note_card.dart';
import '../../models/Note.dart';
import '../../utils/responsive.dart';
import '../note/note_editor.dart';
import 'components/modify_notes_bar.dart';
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
  String activeNoteId = '';

  Future<void> loadNotes({forceSync = false}) async {
    final db = ref.read(dbProvider);
    final searchQuery = ref.read(searchProvider);
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final searchQuery = ref.watch(searchProvider);
    ref.listen<SearchQuery>(searchProvider, (_, sq) {
      if (queryController.text != sq.query) {
        queryController.text = sq.query;
      }
      loadNotes();
    });
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
                onMenuPressed: db.openDrawer,
                controller: queryController,
                focusNode: widget.searchFocusNode,
              ),
            ),
      body: SafeArea(
        right: false,
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
      ),
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
