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
  handleTap() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Dialog(
          child: Text('handleTap'),
        );
      },
    );
  }

  handleSourcePress() {}

  handleMenuPress() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const Dialog(
          child: Text('handleMenuPress'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(viewedNotesProvider);
    return ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, i) {
          return LargeNoteCard(
            note: notes[i],
            onTap: handleTap,
            onSourcePress: handleSourcePress,
            onMenuPress: handleMenuPress,
          );
        });
  }
}
