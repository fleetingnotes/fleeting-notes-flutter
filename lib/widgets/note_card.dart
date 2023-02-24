import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'note_source.dart';

class NoteCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Card(
          elevation: (isActive || isSelected) ? 0 : null,
          color:
              (isActive) ? Theme.of(context).colorScheme.surfaceVariant : null,
          shape: (isSelected)
              ? RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title.isNotEmpty)
                        CustomRichText(
                          text: note.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          sQuery: sQuery,
                          maxLines: 1,
                        ),
                      if (note.content.isNotEmpty)
                        CustomRichText(
                          text: note.content,
                          style: Theme.of(context).textTheme.bodySmall,
                          sQuery: sQuery,
                          maxLines: 3,
                        ),
                      if (note.source.isNotEmpty)
                        NoteSource(source: note.source, height: 100),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(note.getShortDateTimeStr(),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          )),
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
