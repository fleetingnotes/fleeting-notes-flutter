import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TitleLinks extends StatefulWidget {
  const TitleLinks({
    Key? key,
    required this.focusNode,
    required this.caretOffset,
    required this.allLinks,
    required this.query,
    required this.onLinkSelect,
    required this.layerLink,
  }) : super(key: key);

  final FocusNode focusNode;
  final Offset caretOffset;
  final List allLinks;
  final String query;
  final Function onLinkSelect;
  final LayerLink layerLink;

  @override
  State<TitleLinks> createState() => _TitleLinksState();
}

class _TitleLinksState extends State<TitleLinks> {
  int selectedIndex = 0;
  double width = 300;
  late Offset newCaretOffset;
  late List filteredTitles = filterTitles(widget.query);

  @override
  void initState() {
    newCaretOffset = widget.caretOffset;
    if (width + widget.caretOffset.dx > widget.layerLink.leaderSize!.width) {
      newCaretOffset = Offset(
          widget.layerLink.leaderSize!.width - width, widget.caretOffset.dy);
    }
  }

  List filterTitles(query) {
    return widget.allLinks
        .where((title) => title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void onKeyEvent(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        selectedIndex = min(selectedIndex + 1, filteredTitles.length - 1);
      });
    } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        selectedIndex = max(selectedIndex - 1, 0);
      });
    } else if (e.logicalKey == LogicalKeyboardKey.enter) {
      widget.onLinkSelect(filteredTitles[selectedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    filteredTitles = filterTitles(widget.query);
    double tileHeight = 50;
    return Positioned(
      width: width,
      height: min(150, filteredTitles.length * tileHeight),
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: newCaretOffset,
        child: Material(
          child: KeyboardListener(
            focusNode: widget.focusNode,
            onKeyEvent: onKeyEvent,
            child: ListView.builder(
              itemCount: filteredTitles.length,
              itemExtent: tileHeight,
              itemBuilder: (context, index) {
                final String item = filteredTitles[index];
                return MouseRegion(
                  onEnter: (e) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: ListTile(
                    tileColor: (index == selectedIndex) ? Colors.blue : null,
                    hoverColor: Colors.transparent,
                    title: Text(item),
                    onTap: () {
                      widget.onLinkSelect(item);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
