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
    return Positioned(
      width: 125,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: caretOffset,
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
