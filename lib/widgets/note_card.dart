import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'note_source.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    Key? key,
    required this.note,
    this.onLongPress,
    this.onTap,
    this.sQuery,
    this.isActive = false,
    this.isSelected = false,
  }) : super(key: key);

  final bool isActive;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Note note;
  final SearchQuery? sQuery;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool hovering = false;

  onSelect(bool? value) {
    if (value == true) {
      widget.onLongPress?.call();
    }
    if (value == false && widget.isSelected) {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        hovering = true;
      }),
      onExit: (_) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        child: Card(
            elevation: (widget.isSelected) ? 1 : 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.note.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CustomRichText(
                            text: widget.note.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            sQuery: widget.sQuery,
                            maxLines: 1,
                          ),
                        ),
                      if (widget.note.content.isNotEmpty)
                        Flexible(
                          child: CustomRichText(
                            text: widget.note.content,
                            style: Theme.of(context).textTheme.bodySmall,
                            sQuery: widget.sQuery,
                          ),
                        ),
                      if (widget.note.source.isNotEmpty)
                        NoteSource(source: widget.note.source, height: 100),
                    ],
                  ),
                  if (hovering || widget.isSelected)
                    Positioned(
                        top: 0,
                        right: 0,
                        child: Checkbox(
                          onChanged: onSelect,
                          value: widget.isSelected,
                        )),
                  if (hovering)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(widget.note.getShortDateTimeStr(),
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                ],
              ),
            )),
      ),
    );
  }
}

class CustomRichText extends StatelessWidget {
  const CustomRichText({
    Key? key,
    required this.text,
    this.style,
    this.highlightStyle,
    this.sQuery,
    this.maxLines,
  }) : super(key: key);

  final String text;
  final SearchQuery? sQuery;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;

  List<TextSpan> highlightString(BuildContext context, String query,
      String text, TextStyle? highlightStyle, TextStyle? defaultStyle) {
    RegExp r = getQueryRegex(query);
    defaultStyle ??= const TextStyle();
    highlightStyle ??= defaultStyle.copyWith(
      backgroundColor: Theme.of(context).highlightColor,
    );
    int placeHolder = 0;
    List<TextSpan> textSpanner = [];
    final element = r.firstMatch(text);
    if (element != null) {
      if (textSpanner.isNotEmpty) {
        textSpanner.add(TextSpan(
            text: text.substring(placeHolder, element.start),
            style: defaultStyle));
      } else {
        int prev = max(element.start - 10, 0);
        if (prev > 0) {
          textSpanner.add(TextSpan(text: "...", style: defaultStyle));
        }
        textSpanner.add(TextSpan(
            text: text.substring(prev, element.start), style: defaultStyle));
      }
      textSpanner.add(TextSpan(
          text: text.substring(element.start, element.end),
          style: highlightStyle));
      placeHolder = element.end;
    }
    textSpanner.add(TextSpan(
        text: text.substring(placeHolder, text.length), style: defaultStyle));
    return textSpanner;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
          children: highlightString(
        context,
        (sQuery != null && sQuery!.searchByTitle) ? sQuery!.query : '',
        text,
        highlightStyle,
        style,
      )),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
