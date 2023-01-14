import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import '../../../../models/Note.dart';

class LinkPreview extends StatelessWidget {
  const LinkPreview({
    Key? key,
    required this.note,
    required this.caretOffset,
    required this.onTap,
    required this.layerLink,
  }) : super(key: key);

  final Note note;
  final Offset caretOffset;
  final VoidCallback onTap;
  final LayerLink layerLink;

  @override
  Widget build(BuildContext context) {
    double width = 300;
    Offset newCaretOffset = caretOffset;
    if (width + caretOffset.dx > layerLink.leaderSize!.width) {
      newCaretOffset =
          Offset(layerLink.leaderSize!.width - width, caretOffset.dy);
    }
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: newCaretOffset,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: NoteCard(
            note: note,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
