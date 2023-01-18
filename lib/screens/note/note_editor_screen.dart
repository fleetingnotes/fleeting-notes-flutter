import 'dart:typed_data';

import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/Note.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';
import '../../services/providers.dart';
import '../../utils/responsive.dart';
import 'components/note_popup_menu.dart';
import 'note_editor.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.note,
    required this.isShared,
    this.appbarElevation,
  });

  final Note note;
  final bool isShared;
  final double? appbarElevation;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  TextEditingController contentController = StyleableTextFieldController(
    styles: TextPartStyleDefinitions(definitionList: [
      TextPartStyleDefinition(
          pattern: Note.linkRegex,
          style: const TextStyle(
            color: Color.fromARGB(255, 138, 180, 248),
            decoration: TextDecoration.underline,
          ))
    ]),
  );
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final noteUtils = ref.watch(noteUtilsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: (Responsive.isMobile(context)) ? null : dialogElevation,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          title:
              Text("Edit Note", style: Theme.of(context).textTheme.titleLarge),
          actions: [
            ValueListenableBuilder(
                valueListenable:
                    settings.box.listenable(keys: ['unsaved-note']),
                builder: (context, Box box, _) {
                  var unsavedNote = box.get('unsaved-note');
                  bool saveEnabled =
                      unsavedNote != null && unsavedNote?.id == widget.note.id;
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
                note: widget.note,
                onAddAttachment: (String fn, Uint8List? fb) {
                  noteUtils.onAddAttachment(context, widget.note, fn, fb,
                      controller: contentController);
                },
              ),
            )
          ],
        ),
        Flexible(
          fit: FlexFit.loose,
          child: NoteEditor(
            note: widget.note,
            contentController: contentController,
            isShared: widget.isShared,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          ),
        ),
      ],
    );
  }
}
