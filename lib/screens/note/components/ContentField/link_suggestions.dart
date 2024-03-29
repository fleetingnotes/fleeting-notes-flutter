import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/widgets/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Suggestions extends StatefulWidget {
  const Suggestions({
    Key? key,
    required this.caretOffset,
    required this.suggestions,
    required this.query,
    required this.onSelect,
    required this.layerLink,
  }) : super(key: key);

  final Offset caretOffset;
  final List<String> suggestions;
  final String query;
  final Function(String) onSelect;
  final LayerLink layerLink;

  @override
  State<Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {
  int selectedIndex = 0;
  double width = 300;
  late Offset newCaretOffset;
  late List<String> filteredTitles = filterTitles(widget.query);

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

  List<String> filterTitles(query) {
    return widget.suggestions
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
      widget.onSelect(filteredTitles[selectedIndex]);
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
                    widget.onSelect(item);
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
