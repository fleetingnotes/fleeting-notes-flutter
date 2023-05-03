import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkSuggestions extends StatefulWidget {
  const LinkSuggestions({
    Key? key,
    required this.caretOffset,
    required this.allLinks,
    required this.query,
    required this.onLinkSelect,
    required this.layerLink,
    required this.focusNode,
  }) : super(key: key);

  final Offset caretOffset;
  final List allLinks;
  final String query;
  final Function onLinkSelect;
  final LayerLink layerLink;
  final FocusNode focusNode;

  @override
  State<LinkSuggestions> createState() => _LinkSuggestionsState();
}

class _LinkSuggestionsState extends State<LinkSuggestions> {
  int selectedIndex = 0;
  double width = 300;
  late Offset newCaretOffset;
  late List filteredTitles = filterTitles(widget.query);

  @override
  void initState() {
    super.initState();
    newCaretOffset = widget.caretOffset;
    if (width + widget.caretOffset.dx > widget.layerLink.leaderSize!.width) {
      newCaretOffset = Offset(
          widget.layerLink.leaderSize!.width - width, widget.caretOffset.dy);
    }
    HardwareKeyboard.instance.addHandler(onKeyEvent);
  }

  @override
  void dispose() {
    super.dispose();
    HardwareKeyboard.instance.removeHandler(onKeyEvent);
  }

  List filterTitles(query) {
    return widget.allLinks
        .where((title) => title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  bool onKeyEvent(KeyEvent e) {
    if (e is! KeyDownEvent || filteredTitles.isEmpty) return false;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        selectedIndex = min(selectedIndex + 1, filteredTitles.length - 1);
      });
      return true;
    } else if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        selectedIndex = max(selectedIndex - 1, 0);
      });
      return true;
    } else if (e.logicalKey == LogicalKeyboardKey.enter) {
      widget.onLinkSelect(filteredTitles[selectedIndex]);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    filteredTitles = filterTitles(widget.query);
    const double tileHeight = 50;
    const int maxDisplayed = 3;
    return Positioned(
      width: width,
      height:
          min(tileHeight * maxDisplayed, filteredTitles.length * tileHeight),
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: newCaretOffset,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
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
                  tileColor: (index == selectedIndex)
                      ? Theme.of(context).hoverColor
                      : null,
                  hoverColor: Colors.transparent,
                  title: CustomRichText(
                    maxLines: 1,
                    text: item,
                    sQuery: SearchQuery(query: widget.query),
                    style: Theme.of(context).textTheme.bodyMedium,
                    highlightStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    widget.onLinkSelect(item);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
