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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              IconButton(
                  onPressed: onForward, icon: const Icon(Icons.arrow_forward)),
            ],
          ),
        ),
      ],
    );
  }
}
