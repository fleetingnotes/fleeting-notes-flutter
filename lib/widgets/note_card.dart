import 'dart:math';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/Note.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    Key? key,
    required this.note,
    this.onSelect,
    this.onTap,
    this.sQuery,
    this.isActive = false,
    this.isSelected = false,
    this.expanded = false,
    this.maxLines,
  }) : super(key: key);

  final bool isActive;
  final bool isSelected;
  final bool expanded;
  final VoidCallback? onSelect;
  final VoidCallback? onTap;
  final Note note;
  final SearchQuery? sQuery;
  final int? maxLines;

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
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    var sourceMetadata = widget.note.sourceMetadata;
    double elevation = (widget.isSelected) ? 1 : 0;
    return GestureDetector(
      onLongPress: widget.onSelect,
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() {
          hovering = true;
        }),
        onExit: (_) => setState(() {
          hovering = false;
        }),
        child: Card(
          clipBehavior: Clip.hardEdge,
          elevation: elevation,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.note.title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomRichText(
                                text: widget.note.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                sQuery: widget.sQuery,
                                maxLines: 1,
                              ),
                            ),
                          if (widget.note.content.isNotEmpty)
                            Flexible(
                              fit: (widget.expanded)
                                  ? FlexFit.tight
                                  : FlexFit.loose,
                              child: CustomRichText(
                                text: widget.note.content,
                                style: Theme.of(context).textTheme.bodySmall,
                                sQuery: widget.sQuery,
                                maxLines: widget.maxLines,
                              ),
                            ),
                          if (widget.expanded && widget.note.content.isEmpty)
                            const Spacer(),
                        ],
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
              ),
              if (widget.onSelect != null && (hovering || widget.isSelected))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Card(
                    elevation: elevation,
                    margin: EdgeInsets.zero,
                    shadowColor: Colors.transparent,
                    child: Checkbox(
                      onChanged: onSelect,
                      value: widget.isSelected,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomRichText extends ConsumerWidget {
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
    List<TextSpan> textSpanner = [];
    final element = r.firstMatch(text);
    if (element != null) {
      // clip part before highlight
      int prev = max(element.start - 10, 0);
      String preHighlightText =
          '${(prev > 0) ? "..." : ""}${text.substring(prev, element.start)}';
      if (preHighlightText.isNotEmpty) {
        textSpanner.add(TextSpan(text: preHighlightText, style: defaultStyle));
      }

      String highlightText = text.substring(element.start, element.end);
      if (highlightText.isNotEmpty) {
        textSpanner.add(TextSpan(text: highlightText, style: highlightStyle));
      }

      String postHighlightText = text.substring(element.end, text.length);
      if (postHighlightText.isNotEmpty) {
        textSpanner.add(TextSpan(text: postHighlightText, style: defaultStyle));
      }
    } else {
      textSpanner.add(TextSpan(text: text, style: defaultStyle));
    }
    return textSpanner;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final db = ref.read(dbProvider);
    final textScale = settings.get('text-scale-factor') ?? 1.0;
    TextStyle updatedStyle = style ?? const TextStyle();
    double newFontSize = (updatedStyle.fontSize ?? 1.0) * textScale;
    updatedStyle = updatedStyle.copyWith(fontSize: newFontSize);
    TextDirection textDirection =
        db.settings.get('right-to-left', defaultValue: false)
            ? TextDirection.rtl
            : TextDirection.ltr;

    return RichText(
      text: TextSpan(
          children: highlightString(
        context,
        (sQuery != null && sQuery!.searchByTitle) ? sQuery!.query : '',
        text,
        highlightStyle,
        updatedStyle,
      )),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textDirection: textDirection,
    );
  }
}
