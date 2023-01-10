import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

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
                          style: Theme.of(context).textTheme.titleMedium,
                          isActive: isActive,
                          sQuery: sQuery,
                          maxLines: 1,
                        ),
                      if (note.content.isNotEmpty)
                        CustomRichText(
                          text: note.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                          isActive: isActive,
                          sQuery: sQuery,
                          maxLines: 3,
                        ),
                      if (note.source.isNotEmpty)
                        NoteSource(source: note.source),
                    ],
                  ),
                ),
                Text(note.getShortDateTimeStr(),
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          )),
    );
  }
}

class NoteSource extends StatelessWidget {
  const NoteSource({
    Key? key,
    required this.source,
  }) : super(key: key);

  final String source;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      width: double.infinity,
      imageUrl: source,
      imageBuilder: (context, imageProvider) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        );
      },
      errorWidget: (context, url, err) => Container(),
    );
  }
}

class CustomRichText extends StatelessWidget {
  const CustomRichText({
    Key? key,
    required this.text,
    this.style,
    this.isActive = false,
    this.sQuery,
    this.maxLines,
  }) : super(key: key);

  final String text;
  final SearchQuery? sQuery;
  final bool isActive;
  final TextStyle? style;
  final int? maxLines;

  List<TextSpan> highlightString(String query, String text,
      Color highlightColor, TextStyle? defaultStyle) {
    RegExp r = getQueryRegex(query);
    defaultStyle ??= const TextStyle();
    TextStyle highlight =
        defaultStyle.copyWith(backgroundColor: highlightColor);
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
          text: text.substring(element.start, element.end), style: highlight));
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
        (sQuery != null && sQuery!.searchByTitle) ? sQuery!.query : '',
        text,
        Theme.of(context).highlightColor,
        style,
      )),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
