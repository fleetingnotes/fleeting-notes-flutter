import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    Key? key,
    required this.note,
    this.onSelect,
    this.onTap,
    this.sQuery,
    this.isActive = false,
    this.isSelected = false,
  }) : super(key: key);

  final bool isActive;
  final bool isSelected;
  final VoidCallback? onSelect;
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
      widget.onSelect?.call();
    }
    if (value == false && widget.isSelected) {
      widget.onTap?.call();
    }
  }

  void onPressedPreview(String url) {
    Uri uri = Uri.parse(url);
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    var sourceMetadata = widget.note.sourceMetadata;
    return GestureDetector(
      onLongPress: widget.onSelect,
      onTap: widget.onTap,
      child: Card(
          elevation: (widget.isSelected) ? 1 : 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() {
                    hovering = true;
                  }),
                  onExit: (_) => setState(() {
                    hovering = false;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      fit: StackFit.expand,
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
                                  maxLines: null,
                                ),
                              ),
                          ],
                        ),
                        if (widget.onSelect != null &&
                            (hovering || widget.isSelected))
                          Positioned(
                              top: 0,
                              right: 0,
                              child: Checkbox(
                                onChanged: onSelect,
                                value: widget.isSelected,
                              )),
                        if (hovering && widget.onSelect != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Text(widget.note.getShortDateTimeStr(),
                                style: Theme.of(context).textTheme.labelSmall),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!sourceMetadata.isEmpty)
                SourcePreview(
                  height: 75,
                  metadata: sourceMetadata,
                  onPressed: () => onPressedPreview(sourceMetadata.url),
                )
            ],
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
      overflow: TextOverflow.clip,
    );
  }
}
