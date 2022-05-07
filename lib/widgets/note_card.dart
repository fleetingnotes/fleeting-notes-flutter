import 'dart:math';

import 'package:fleeting_notes_flutter/models/search_query.dart';

import '../models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    this.sQuery,
    this.isActive = false,
  }) : super(key: key);

  final bool isActive;
  final VoidCallback onTap;
  final Note note;
  final SearchQuery? sQuery;

  List<TextSpan> highlightString(
      String query, String text, TextStyle defaultStyle) {
    String escapedQuery =
        query.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
      return '\\${match.group(0)}';
    });
    TextStyle highlight = defaultStyle.copyWith(backgroundColor: Colors.orange);
    RegExp r = RegExp(escapedQuery, multiLine: true, caseSensitive: false);
    int placeHolder = 0;
    List<TextSpan> textSpanner = [];
    r.allMatches(text).forEach((element) {
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
    });
    textSpanner.add(TextSpan(
        text: text.substring(placeHolder, text.length), style: defaultStyle));
    return textSpanner;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Theme.of(context).custom.kDefaultPadding,
            vertical: Theme.of(context).custom.kDefaultPadding / 2),
        child: NeumorphicButton(
          padding: const EdgeInsets.all(0),
          style: NeumorphicStyle(
            depth: (isActive) ? 0 : 2,
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).scaffoldBackgroundColor,
            shadowLightColor: Theme.of(context).custom.lightShadow,
            shadowDarkColor: Theme.of(context).custom.darkShadow,
          ),
          onPressed: onTap,
          child: Container(
            padding: EdgeInsets.all(Theme.of(context).custom.kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.title != '')
                              RichText(
                                  text: TextSpan(
                                      children: highlightString(
                                          (sQuery != null &&
                                                  sQuery!.searchByTitle)
                                              ? sQuery!.queryRegex
                                              : '',
                                          note.title,
                                          Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                color: isActive
                                                    ? Colors.white
                                                    : null,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ))),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            if (note.content != '')
                              RichText(
                                  text: TextSpan(
                                      children: highlightString(
                                          (sQuery != null &&
                                                  sQuery!.searchByContent)
                                              ? sQuery!.queryRegex
                                              : '',
                                          note.content,
                                          Theme.of(context)
                                              .textTheme
                                              .bodyText2!
                                              .copyWith(
                                                color: isActive
                                                    ? Colors.white
                                                    : null,
                                              ))),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                          ]),
                    ),
                    SizedBox(width: Theme.of(context).custom.kDefaultPadding),
                    Column(
                      children: [
                        Text(
                          note.getShortDateTimeStr(),
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                color: isActive ? Colors.white70 : null,
                              ),
                        ),
                        const SizedBox(height: 5),
                        // if (note.hasAttachment) // TODO: Add attachment
                        //   Icon(
                        //     Icons.attachment,
                        //     size: 15,
                        //     color: isActive
                        //         ? Colors.white70
                        //         : Theme.of(context).custom.kGrayColor,
                        //   ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
