import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/large_note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteList extends ConsumerStatefulWidget {
  const NoteList({super.key});

  @override
  ConsumerState<NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<NoteList> {
  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(viewedNotesProvider);
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, i) {
        return LargeNoteCard(
          note: notes[i],
        );
      },
    );
  }
}
