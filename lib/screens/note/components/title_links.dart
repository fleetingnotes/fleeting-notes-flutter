import 'package:flutter/material.dart';

class TitleLinks extends StatelessWidget {
  TitleLinks({
    Key? key,
    required this.caretOffset,
    required this.titles,
    required this.query,
    required this.onLinkSelect,
    required this.layerLink,
  }) : super(key: key);

  final Offset caretOffset;
  final List titles;
  final String query;
  final Function onLinkSelect;
  final LayerLink layerLink;

  List filterTitles(query) {
    return titles
        .where((title) => title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 300,
      height: 100,
      child: CompositedTransformFollower(
        link: layerLink,
        offset: caretOffset,
        child: ListView.builder(
          itemCount: filterTitles(query).length,
          itemBuilder: (context, index) {
            List filteredTitles = filterTitles(query);
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
    );
  }
}
