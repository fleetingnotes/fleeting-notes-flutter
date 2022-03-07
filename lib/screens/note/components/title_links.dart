import 'package:flutter/material.dart';

class TitleLinks extends StatelessWidget {
  const TitleLinks({
    Key? key,
    required this.caretOffset,
    required this.titles,
    required this.onTap,
    required this.layerLink,
  }) : super(key: key);

  final Offset caretOffset;
  final List titles;
  final VoidCallback onTap;
  final LayerLink layerLink;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 125,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: caretOffset,
        child: OutlinedButton(
            onPressed: onTap,
            child: const Text(
              'List of links',
              style: TextStyle(
                fontSize: 15,
              ),
            )),
      ),
    );
  }
}
