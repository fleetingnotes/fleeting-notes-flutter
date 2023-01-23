import 'dart:typed_data';

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
    this.onClose,
    this.contentController,
    this.titleController,
  });

  final Note? note;
  final VoidCallback? onClose;
  final double? elevation;
  final Widget? title;
  final TextEditingController? contentController;
  final TextEditingController? titleController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final settings = ref.watch(settingsProvider);
    final n = note;
    return AppBar(
      scrolledUnderElevation: 0,
      elevation: elevation,
      leading: IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close),
      ),
      title: title,
      actions: [
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
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: NotePopupMenu(
            note: note,
            onAddAttachment: (String fn, Uint8List? fb) {
              if (n == null) return;
              noteUtils.onAddAttachment(context, n, fn, fb,
                  controller: contentController);
            },
          ),
        )
      ],
    );
  }
}
