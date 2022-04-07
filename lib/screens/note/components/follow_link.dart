import 'package:flutter/material.dart';

class FollowLink extends StatelessWidget {
  const FollowLink({
    Key? key,
    required this.caretOffset,
    required this.onTap,
    required this.layerLink,
  }) : super(key: key);

  final Offset caretOffset;
  final VoidCallback onTap;
  final LayerLink layerLink;

  @override
  Widget build(BuildContext context) {
    double width = 125;
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
        child: Material(
          child: OutlinedButton(
              onPressed: onTap,
              child: const Text(
                'Follow Link',
                style: TextStyle(
                  fontSize: 15,
                ),
              )),
        ),
      ),
    );
  }
}
