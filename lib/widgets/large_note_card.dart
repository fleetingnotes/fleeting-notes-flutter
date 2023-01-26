import 'dart:typed_data';

import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_popup_menu.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/Note.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class LargeNoteCard extends ConsumerWidget {
  const LargeNoteCard({
    Key? key,
    required this.note,
  }) : super(key: key);

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteUtils = ref.watch(noteUtilsProvider);
    return GestureDetector(
      onTap: () => noteUtils.navigateToNote(context, note),
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
                      'Saved ${note.getShortDateTimeStr(noteDateTime: note.modifiedAtDate)}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                      decoration: ShapeDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: const CircleBorder(),
                      ),
                      child: NotePopupMenu(
                        note: note,
                        onAddAttachment: (String fn, Uint8List? fb) {
                          noteUtils.onAddAttachment(context, note, fn, fb);
                        },
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectionArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (note.title.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      note.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                    ),
                                  ),
                                if (note.content.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: MarkdownBody(
                                      data: note.content,
                                      softLineBreak: true,
                                      selectable: true,
                                      onTapLink: (text, href, title) {
                                        if (href != null) {
                                          noteUtils.launchURLBrowser(
                                              href, context);
                                        }
                                      },
                                      extensionSet: md.ExtensionSet(
                                        md.ExtensionSet.gitHubFlavored
                                            .blockSyntaxes,
                                        [
                                          md.EmojiSyntax(),
                                          ...md.ExtensionSet.gitHubFlavored
                                              .inlineSyntaxes,
                                        ],
                                      ),
                                    ),
                                  ),
                                if (note.source.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: SourceContainer(
                                        text: note.source, readOnly: true),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
