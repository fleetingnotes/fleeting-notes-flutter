import 'package:fleeting_notes_flutter/screens/note/components/note_editor_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/screens/note/stylable_textfield_controller.dart';
import 'package:flutter/material.dart';

import '../../models/Note.dart';
import '../../models/text_part_style_definition.dart';
import '../../models/text_part_style_definitions.dart';

class NoteEditorCard extends StatefulWidget {
  const NoteEditorCard({
    super.key,
    required this.note,
    this.title,
    this.elevation = 1,
    this.onClose,
  });

  final Note note;
  final Widget? title;
  final double elevation;
  final VoidCallback? onClose;

  @override
  State<NoteEditorCard> createState() => _NoteEditorCardState();
}

class _NoteEditorCardState extends State<NoteEditorCard> {
  final TextEditingController contentController = StyleableTextFieldController(
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
    return Card(
      elevation: widget.elevation,
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          NoteEditorAppBar(
            elevation: widget.elevation,
            note: widget.note,
            title: widget.title,
            contentController: contentController,
            onClose: widget.onClose,
          ),
          Flexible(
            fit: FlexFit.loose,
            child: NoteEditor(
              note: widget.note,
              contentController: contentController,
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            ),
          ),
        ],
      ),
    );
  }
}
