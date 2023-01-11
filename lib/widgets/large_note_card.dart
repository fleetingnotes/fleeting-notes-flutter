import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class LargeNoteCard extends StatelessWidget {
  const LargeNoteCard({
    Key? key,
    required this.note,
    this.onTap,
    this.onSourcePress,
    this.onMenuPress,
    this.sQuery,
  }) : super(key: key);

  final VoidCallback? onTap;
  final VoidCallback? onSourcePress;
  final VoidCallback? onMenuPress;
  final Note note;
  final SearchQuery? sQuery;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: onTap,
      child: Card(
          child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                if (!note.isEmpty())
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Saved At ${note.getShortDateTimeStr(noteDateTime: note.modifiedAtDate)}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: const CircleBorder(),
                    ),
                    child: IconButton(
                      onPressed: onMenuPress,
                      icon: const Icon(
                        Icons.more_vert,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.title.isNotEmpty)
                        Text(
                          note.title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                        ),
                      if (note.content.isNotEmpty)
                        MarkdownBody(
                          data: note.content,
                          softLineBreak: true,
                          extensionSet: md.ExtensionSet(
                              md.ExtensionSet.gitHubFlavored.blockSyntaxes, [
                            md.EmojiSyntax(),
                            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                          ]),
                        ),
                      if (note.source.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  note.source,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link),
                              onPressed: onSourcePress,
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
