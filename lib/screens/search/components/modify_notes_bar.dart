import 'package:flutter/material.dart';
import '../../../models/Note.dart';

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
      toolbarHeight: 72,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: clearNotes,
      ),
      title: Text(
        '${selectedNotes.length} notes selected',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
