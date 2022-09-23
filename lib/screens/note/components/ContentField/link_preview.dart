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
      height: 150,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: newCaretOffset,
        child: Material(
          child: OutlinedButton(
              onPressed: onTap,
              style: const ButtonStyle(alignment: Alignment.topLeft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    note.title,
                    maxLines: 1,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyText1?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    note.content,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  const Spacer(),
                  Text(note.longCreated,
                      style: Theme.of(context).textTheme.caption),
                  const SizedBox(height: 15)
                ],
              )),
        ),
      ),
    );
  }
}
