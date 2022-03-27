import 'dart:math';

import 'package:flutter/material.dart';

class TitleLinks extends StatelessWidget {
  const TitleLinks({
    Key? key,
    required this.caretOffset,
    required this.allLinks,
    required this.query,
    required this.onLinkSelect,
    required this.layerLink,
  }) : super(key: key);

  final Offset caretOffset;
  final List allLinks;
  final String query;
  final Function onLinkSelect;
  final LayerLink layerLink;

  List filterTitles(query) {
    return allLinks
        .where((title) => title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = 300;
    Offset newCaretOffset = caretOffset;
    if (width + caretOffset.dx > layerLink.leaderSize!.width) {
      newCaretOffset += Offset(-width, 0);
    }
    List filteredTitles = filterTitles(query);
    double tileHeight = 50;
    return Positioned(
      width: width,
      height: min(150, filteredTitles.length * tileHeight),
      child: CompositedTransformFollower(
        link: layerLink,
        offset: newCaretOffset,
        child: Material(
          child: ListView.builder(
            itemCount: filteredTitles.length,
            itemExtent: tileHeight,
            itemBuilder: (context, index) {
              final String item = filteredTitles[index];
              return ListTile(
                title: Text(item),
                onTap: () {
                  onLinkSelect(item);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
