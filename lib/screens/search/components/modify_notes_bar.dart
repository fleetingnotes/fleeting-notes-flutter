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
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: clearNotes, icon: const Icon(Icons.close)),
            const SizedBox(width: 16),
            Text(
              "${selectedNotes.length} notes selected",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteNotes(context),
            )
          ],
        ),
      ),
    );
  }
}
