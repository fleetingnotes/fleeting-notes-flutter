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
    if (notes.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
          ),
          const SizedBox(height: 4),
          Text(
            'Notes you view appear here',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, right: 8),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        return LargeNoteCard(
          note: notes[i],
        );
      },
    );
  }
}
