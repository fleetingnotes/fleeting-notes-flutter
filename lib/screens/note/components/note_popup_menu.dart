import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class NotePopupMenu extends StatefulWidget {
  const NotePopupMenu({
    Key? key,
    this.onDelete,
    this.onAddAttachment,
    this.onCopyUrl,
    this.onShareChange,
    this.isNoteShareable = false,
  }) : super(key: key);

  final VoidCallback? onCopyUrl;
  final VoidCallback? onDelete;
  final Function(String, Uint8List?)? onAddAttachment;
  final Function(bool)? onShareChange;
  final bool isNoteShareable;

  @override
  State<NotePopupMenu> createState() => _NotePopupMenuState();
}

class _NotePopupMenuState extends State<NotePopupMenu> {
  late bool _isShareable;

  @override
  void initState() {
    _isShareable = widget.isNoteShareable;
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
        if (widget.onCopyUrl != null)
          PopupMenuItem(
            child: ListTile(
              title: const Text("Share URL"),
              leading: const Icon(Icons.link),
              contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
              trailing: widget.onShareChange == null
                  ? null
                  : Tooltip(
                      child: StatefulBuilder(builder: (context, setState) {
                        return Checkbox(
                            value: _isShareable,
                            onChanged: (val) {
                              setState(() {
                                _isShareable = val ?? false;
                              });
                              widget.onShareChange?.call(_isShareable);
                            });
                      }),
                      message: 'Is shareable',
                    ),
            ),
            onTap: () {
              setState(() {
                _isShareable = true;
              });
              widget.onShareChange?.call(_isShareable);
              widget.onCopyUrl?.call();
            },
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            child: const ListTile(
              title: Text("Delete"),
              leading: Icon(Icons.delete),
              contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
            ),
            onTap: () {
              widget.onDelete?.call();
            },
          ),
      ],
    );
  }
}
