import 'package:flutter/material.dart';

class NoteEditorBottomAppBar extends StatelessWidget {
  const NoteEditorBottomAppBar({
    super.key,
    this.onBack,
    this.onForward,
  });

  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          IconButton(
              onPressed: onForward, icon: const Icon(Icons.arrow_forward)),
        ],
      ),
    );
  }
}
