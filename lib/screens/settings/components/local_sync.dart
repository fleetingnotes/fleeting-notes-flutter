import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';

class LocalSync extends StatefulWidget {
  const LocalSync({
    Key? key,
    required this.settings,
  }) : super(key: key);

  final Settings settings;
  @override
  State<LocalSync> createState() => _LocalSyncState();
}

class _LocalSyncState extends State<LocalSync> {
  bool enabled = false;
  String? syncDir;
  TextEditingController controller = TextEditingController();
  String initNoteTemplate = r'''
---
id: "${id}"
title: "${title}"
source: "${source}"
created_date: "${created_time}"
modified_date: "${last_modified_time}"
---
${content}''';
  @override
  void initState() {
    enabled = widget.settings.get('local-sync-enabled', defaultValue: false);
    syncDir = widget.settings.get('local-sync-dir');
    controller.text = widget.settings
        .get('local-sync-template', defaultValue: initNoteTemplate);
    super.initState();
  }

  void onFolderSelect() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        syncDir = selectedDirectory;
      });
    }
    updateHiveDb();
  }

  void onSwitchChange(bool val) {
    setState(() {
      enabled = val;
    });
    updateHiveDb();
  }

  void onNoteTemplateChange(String val) {
    setState(() {
      controller.text = val;
    });
    updateHiveDb();
  }

  void onRefreshNoteTemplate() {
    setState(() {
      controller.text = initNoteTemplate;
    });
    updateHiveDb();
  }

  void updateHiveDb() {
    widget.settings.set('local-sync-enabled', enabled);
    widget.settings.set('local-sync-dir', syncDir);
    widget.settings.set('local-sync-template', controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ExpansionTile(
          title: const Text('Local File Sync (One-way)'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SettingItem(
                  title: 'Enabled',
                  description: 'Enable local file sync (Disabled on web)',
                  widget: Switch(
                    value: enabled,
                    onChanged: (kIsWeb) ? null : onSwitchChange,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SettingItem(
                title: 'Sync folder location',
                description: '$syncDir',
                widget: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: (kIsWeb) ? null : onFolderSelect,
                  icon: const Icon(Icons.folder_open),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  SettingItem(
                    title: 'Note template',
                    description: '`id` is necessary in metadata',
                    widget: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: (kIsWeb) ? null : onRefreshNoteTemplate,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    onChanged: onNoteTemplateChange,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    maxLines: null,
                  )
                ],
              ),
            ),
          ]),
    );
  }
}
