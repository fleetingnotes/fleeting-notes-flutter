import 'dart:typed_data';

import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/Note.dart';
import '../../../services/providers.dart';
import 'note_popup_menu.dart';

class NoteEditorAppBar extends ConsumerWidget {
  const NoteEditorAppBar({
    super.key,
    required this.note,
    this.elevation,
    this.title,
    this.onBack,
    this.onForward,
    this.onClose,
    this.contentController,
    this.titleController,
  });

  final Note? note;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onClose;
  final double? elevation;
  final Widget? title;
  final TextEditingController? contentController;
  final TextEditingController? titleController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final settings = ref.watch(settingsProvider);
    final sqNotifier = ref.watch(searchProvider.notifier);
    final n = note;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          const Spacer(),
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          IconButton(
              onPressed: onForward, icon: const Icon(Icons.arrow_forward)),
          const Spacer(),
          ValueListenableBuilder(
              valueListenable: settings.box.listenable(keys: ['unsaved-note']),
              builder: (context, Box box, _) {
                var unsavedNote = box.get('unsaved-note');
                bool saveEnabled =
                    unsavedNote != null && n != null && unsavedNote?.id == n.id;
                return IconButton(
                    onPressed: (saveEnabled)
                        ? () {
                            noteUtils.handleSaveNote(context, unsavedNote);
                          }
                        : null,
                    icon: const Icon(Icons.save));
              }),
          if (Responsive.isMobile(context))
            IconButton(
              onPressed: () => sqNotifier.updateSearch(SearchQuery()),
              icon: const Icon(Icons.search),
            ),
          NotePopupMenu(
            note: note,
            onAddAttachment: (String fn, Uint8List? fb) {
              if (n == null) return;
              noteUtils.onAddAttachment(context, n, fn, fb,
                  controller: contentController);
            },
          ),
          OutlinedButton(
            onPressed: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: const [
                  Icon(Icons.link),
                  SizedBox(width: 8),
                  Text('Backlinks'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
