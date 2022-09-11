import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Header extends StatefulWidget {
  const Header({
    Key? key,
    required this.onSave,
    required this.onDelete,
    required this.onSearch,
    required this.onAddAttachment,
    required this.onCopyUrl,
    required this.onShareChange,
    required this.analytics,
    this.title = '',
    this.isNoteShareable = false,
  }) : super(key: key);

  final Function? onSave;
  final VoidCallback? onCopyUrl;
  final VoidCallback? onDelete;
  final Function onAddAttachment;
  final Function? onShareChange;
  final VoidCallback onSearch;
  final FirebaseAnalytics analytics;
  final String title;
  final bool isNoteShareable;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late bool _isShareable;

  @override
  void initState() {
    _isShareable = widget.isNoteShareable;
    super.initState();
  }

  void _onBack(context) {
    widget.analytics.logEvent(name: 'go_back_notecard');
    Navigator.of(context).pop();
  }

  void newSave(context) async {
    await widget.onSave?.call();
    widget.analytics.logEvent(name: 'click_save_note');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Saved'),
      duration: Duration(seconds: 2),
    ));
  }

  void addAttachment() async {
    widget.analytics.logEvent(name: 'click_add_attachment');
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      PlatformFile file = result.files.first;
      Uint8List? fileBytes = file.bytes;
      String filename = file.name;
      widget.onAddAttachment(filename, fileBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Theme.of(context).custom.kDefaultPadding / 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                (Navigator.canPop(context)) ? () => _onBack(context) : null,
          ),
          SizedBox(width: Theme.of(context).custom.kDefaultPadding / 2),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: widget.onSave == null ? null : () => newSave(context),
          ),
          if (Responsive.isMobile(context))
            IconButton(
                icon: const Icon(Icons.search), onPressed: widget.onSearch),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
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
                    contentPadding:
                        const EdgeInsets.only(left: 0.0, right: 0.0),
                    trailing: widget.onShareChange == null
                        ? null
                        : Tooltip(
                            child:
                                StatefulBuilder(builder: (context, setState) {
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
                    widget.analytics.logEvent(name: 'click_copy_url');
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
                    widget.analytics.logEvent(name: 'click_delete_note');
                    widget.onDelete?.call();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
