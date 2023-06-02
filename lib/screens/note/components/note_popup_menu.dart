import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/Note.dart';

class NotePopupMenu extends ConsumerStatefulWidget {
  const NotePopupMenu({
    Key? key,
    required this.note,
    this.onAddAttachment,
    this.onShare,
    this.backlinksOption = true,
    this.deleteOption = true,
    this.shareOption = false,
  }) : super(key: key);

  final Note? note;
  final Function(String, Uint8List?)? onAddAttachment;
  final VoidCallback? onShare;
  final bool backlinksOption;
  final bool deleteOption;
  final bool shareOption;

  @override
  ConsumerState<NotePopupMenu> createState() => _NotePopupMenuState();
}

class _NotePopupMenuState extends ConsumerState<NotePopupMenu> {
  bool _isShareable = false;

  @override
  void initState() {
    _isShareable = widget.note?.isShareable ?? false;
    super.initState();
  }

  void addAttachment() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List? fileBytes = file.bytes;
      String filename = file.name;
      widget.onAddAttachment?.call(filename, fileBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final noteHistory = ref.watch(noteHistoryProvider.notifier);
    var note = widget.note;
    if (note == null) {
      return const IconButton(onPressed: null, icon: Icon(Icons.more_vert));
    }
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        if (widget.onAddAttachment != null)
          PopupMenuItem(
            child: const ListTile(
              title: Text("Add Attachment"),
              leading: Icon(Icons.attach_file),
              contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
            ),
            onTap: addAttachment,
          ),
        if (widget.shareOption)
          PopupMenuItem(
            child: ListTile(
              title: const Text("Share URL"),
              leading: const Icon(Icons.link),
              contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
              trailing: Tooltip(
                child: StatefulBuilder(builder: (context, setState) {
                  return Checkbox(
                      value: _isShareable,
                      onChanged: (val) {
                        setState(() {
                          _isShareable = val ?? false;
                        });
                        noteUtils.handleShareChange(note.id, _isShareable);
                      });
                }),
                message: 'Is shareable',
              ),
            ),
            onTap: () async {
              noteUtils.handleShareChange(note.id, _isShareable);
              noteUtils.handleCopyUrl(context, note.id);
              setState(() {
                _isShareable = true;
              });
            },
          ),
        PopupMenuItem(
          child: const ListTile(
            title: Text("Share"),
            leading: Icon(Icons.share),
            contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
          ),
          onTap: widget.onShare,
        ),
        if (widget.deleteOption)
          PopupMenuItem(
            child: const ListTile(
              title: Text("Delete"),
              leading: Icon(Icons.delete),
              contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
            ),
            onTap: () async {
              if (await noteUtils.handleDeleteNote(context, [note])) {
                noteHistory.goBack(context);
              }
            },
          ),
      ],
    );
  }
}
