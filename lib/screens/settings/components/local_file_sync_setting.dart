import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String syncType = 'two-way';
  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    enabled = widget.settings.get('local-sync-enabled', defaultValue: false);
    syncDir = widget.settings.get('local-sync-dir');
    syncType = widget.settings.get('local-sync-type');
    controller.text = widget.settings
        .get('local-sync-template', defaultValue: Note.defaultNoteTemplate);
    super.initState();
  }

  Future<String> _displayTextInputDialog(BuildContext context) async {
    String tempDir = '';
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Create new sync folder'),
            content: TextField(
              onChanged: (value) {
                tempDir = value;
              },
              decoration: const InputDecoration(hintText: "Folder name"),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
    return tempDir;
  }

  void onFolderSelect() async {
    String? selectedDirectory;
    if (Platform.isIOS) {
      String relDir = await _displayTextInputDialog(context);
      if (relDir.isNotEmpty) {
        var appDir = (await getApplicationDocumentsDirectory()).path;
        selectedDirectory = p.join(appDir, 'MyFleetingNotes', relDir);
        Directory(selectedDirectory).createSync(recursive: true);
      }
    } else {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    }
    if (selectedDirectory != null) {
      setState(() {
        syncDir = selectedDirectory;
      });
    }
    await updateHiveDb(init: true);
  }

  void onSwitchChange(bool val) async {
    // disabling doesn't require permission
    if (!val || kIsWeb) {
      setState(() {
        enabled = false;
      });
      return;
    }
    bool androidPerms = Platform.isAndroid &&
        await Permission.manageExternalStorage.request().isGranted;
    bool iOSPerms =
        Platform.isIOS && await Permission.storage.request().isGranted;
    if (androidPerms || iOSPerms) {
      setState(() {
        enabled = val;
      });
      await updateHiveDb(init: true);
    }
  }

  void onSyncTypeChange(String? type) {
    if (type == null) return;
    setState(() {
      syncType = type;
    });
    updateHiveDb(init: true);
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

  Future<void> updateHiveDb({init: false}) async {
    await Future.wait([
      widget.settings.set('local-sync-enabled', enabled),
      widget.settings.set('local-sync-dir', syncDir),
      widget.settings.set('local-sync-type', syncType),
      widget.settings.set('local-sync-template', controller.text),
    ]);
    if (init) {
      var ls = ref.read(localFileSyncProvider);
      List<Note> notes = await widget.getAllNotes();
      ls.init(notes: notes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ExpansionTile(title: const Text('Local File Sync'), children: [
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
                  title: 'Sync Type',
                  description: 'How notes are synced',
                  widget: DropdownButton<String>(
                      value: syncType,
                      items: const [
                        DropdownMenuItem<String>(
                            child: Text('Two-way sync'), value: 'two-way'),
                        DropdownMenuItem<String>(
                            child: Text('One-way sync'), value: 'one-way'),
                      ],
                      onChanged: onSyncTypeChange)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              SettingItem(
                title: 'Note template',
                description:
                    'I don\'t recommend changing this for two-way sync',
                widget: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: (kIsWeb) ? null : onRefreshNoteTemplate,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              TextField(
                controller: controller,
                onChanged: onNoteTemplateChange,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                maxLines: null,
              )
            ],
          ),
        ),
      ]),
    );
  }
}
