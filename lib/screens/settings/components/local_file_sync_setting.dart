import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/Note.dart';

class LocalSyncSetting extends ConsumerStatefulWidget {
  const LocalSyncSetting({
    Key? key,
    required this.settings,
    required this.getAllNotes,
  }) : super(key: key);

  final Settings settings;
  final Function getAllNotes;
  @override
  ConsumerState<LocalSyncSetting> createState() => _LocalSyncSettingState();
}

class _LocalSyncSettingState extends ConsumerState<LocalSyncSetting> {
  bool enabled = false;
  String? syncDir;
  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    enabled = widget.settings.get('local-sync-enabled', defaultValue: false);
    syncDir = widget.settings.get('local-sync-dir');
    controller.text = widget.settings
        .get('local-sync-template', defaultValue: Note.defaultNoteTemplate);
    super.initState();
  }

  void onFolderSelect() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        syncDir = selectedDirectory;
      });
    }
    await updateHiveDb();
    var ls = ref.read(localFileSyncProvider);
    List<Note> notes = await widget.getAllNotes();
    ls.init(notes: notes);
  }

  void onSwitchChange(bool val) async {
    setState(() {
      enabled = val;
    });
    await updateHiveDb();
    List<Note> notes = await widget.getAllNotes();
    var ls = ref.read(localFileSyncProvider);
    ls.init(notes: notes);
  }

  void onNoteTemplateChange(String val) {
    setState(() {
      controller.text = val;
    });
    updateHiveDb();
  }

  void onRefreshNoteTemplate() {
    setState(() {
      controller.text = Note.defaultNoteTemplate;
    });
    updateHiveDb();
  }

  Future<void> updateHiveDb() async {
    await Future.wait([
      widget.settings.set('local-sync-enabled', enabled),
      widget.settings.set('local-sync-dir', syncDir),
      widget.settings.set('local-sync-template', controller.text)
    ]);
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
