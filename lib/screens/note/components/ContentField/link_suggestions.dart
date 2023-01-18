import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
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
  }) : super(key: key);

  final Offset caretOffset;
  final List allLinks;
  final String query;
  final Function onLinkSelect;
  final LayerLink layerLink;

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

  List<TextSpan> highlightString(String text, TextStyle defaultStyle) {
    RegExp r = getQueryRegex(widget.query);
    TextStyle highlight = defaultStyle.copyWith(fontWeight: FontWeight.bold);
    int placeHolder = 0;
    List<TextSpan> textSpanner = [];
    r.allMatches(text).forEach((element) {
      textSpanner.add(TextSpan(
          text: text.substring(placeHolder, element.start),
          style: defaultStyle));
      textSpanner.add(TextSpan(
          text: text.substring(element.start, element.end), style: highlight));
      placeHolder = element.end;
    });
    textSpanner.add(TextSpan(
        text: text.substring(placeHolder, text.length), style: defaultStyle));
    return textSpanner;
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
    double tileHeight = 50;
    return Positioned(
      width: width,
      height: min(150, filteredTitles.length * tileHeight),
      child: CompositedTransformFollower(
        link: widget.layerLink,
        offset: newCaretOffset,
        child: Material(
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
                  title: RichText(
                      text: TextSpan(
                    children: highlightString(
                      item,
                      Theme.of(context).textTheme.bodyMedium!,
                    ),
                  )),
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
