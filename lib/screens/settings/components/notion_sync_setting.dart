import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/services/sync/notion_sync.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/Note.dart';

class NotionSyncSetting extends StatefulWidget {
  const NotionSyncSetting({
    Key? key,
    required this.settings,
    required this.getAllNotes,
  }) : super(key: key);

  final Settings settings;
  final Function getAllNotes;
  @override
  State<NotionSyncSetting> createState() => _NotionSyncSettingState();
}

class _NotionSyncSettingState extends State<NotionSyncSetting> {
  bool enabled = false;
  String? notionToken;
  String? notionDatabaseId;
  String errMessage = '';
  TextEditingController controller = TextEditingController();
  TextEditingController tokenController = TextEditingController();
  TextEditingController databaseIdController = TextEditingController();
  @override
  void initState() {
    enabled = widget.settings.get('notion-sync-enabled', defaultValue: false);
    tokenController.text = widget.settings.get('notion-token');
    databaseIdController.text = widget.settings.get('notion-database-id');
    super.initState();
  }

  void onSwitchChange(bool val) async {
    setState(() {
      enabled = val;
    });
    await updateHiveDb();
    if (val && notionToken != null && notionDatabaseId != null) {
      List<Note> notes = await widget.getAllNotes();
      var ls = NotionSync(settings: widget.settings);
      ls.pushNotes(notes);
    }
  }

  void onTokenChange(String val) {
    setState(() {
      tokenController.text = val;
    });
    updateHiveDb();
  }

  void onDatabaseIdChange(String val) {
    setState(() {
      databaseIdController.text = val;
    });
    updateHiveDb();
  }

  Future<void> updateHiveDb() async {
    var tokenText = tokenController.text;
    await Future.wait([
      widget.settings.set('notion-sync-enabled', enabled),
      widget.settings.set('notion-token', tokenController.text),
      widget.settings.set('notion-database-id', databaseIdController.text),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ExpansionTile(
          title: const Text('Notion Sync (One-way)'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SettingItem(
                  title: 'Enabled',
                  description: 'Enable Notion Sync',
                  widget: Switch(
                    value: enabled,
                    onChanged: onSwitchChange,
                  )),
            ),
            RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Create a new integration ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'here',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch(
                              'https://www.notion.so/my-integrations');
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Enter your integration token',
                  border: OutlineInputBorder(),
                ),
                onChanged: onTokenChange,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: databaseIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter database ID (found in page URL after ".so/")',
                  border: OutlineInputBorder(),
                ),
                onChanged: onDatabaseIdChange,
              ),
          ]),
    );
  }
}
