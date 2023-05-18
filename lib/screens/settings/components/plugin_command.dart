import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PluginCommandTile extends ConsumerStatefulWidget {
  const PluginCommandTile({
    Key? key,
    required this.updateCommandSettings,
    this.alias = '',
    this.commandId = '',
    this.metadata = '',
  }) : super(key: key);

  final String alias;
  final String commandId;
  final String metadata;
  final Function(Map<String, String>?) updateCommandSettings;

  @override
  ConsumerState<PluginCommandTile> createState() => _PluginCommandTileState();
}

class _PluginCommandTileState extends ConsumerState<PluginCommandTile> {
  String alias = '';
  String commandId = '';
  String metadata = '';

  TextEditingController aliasController = TextEditingController();
  TextEditingController commandIdController = TextEditingController();
  TextEditingController metadataController = TextEditingController();

  @override
  void initState() {
    alias = widget.alias;
    commandId = widget.commandId;
    metadata = widget.metadata;

    aliasController.text = alias;
    commandIdController.text = commandId;
    metadataController.text = metadata;

    super.initState();
  }

  void updateSettings() {
    widget.updateCommandSettings({
      "alias": alias,
      "commandId": commandId,
      "metadata": metadata,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      trailing: IconButton(
        onPressed: () => widget.updateCommandSettings(null),
        icon: const Icon(Icons.close),
      ),
      clipBehavior: Clip.hardEdge,
      title: Text((alias.isEmpty) ? "Untitled Command" : alias),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        SettingsItem(
          name: 'Alias',
          description: 'The name used to call this command',
          actions: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: aliasController,
                onChanged: (text) {
                  alias = text;
                  updateSettings();
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            )
          ],
        ),
        SettingsItem(
          name: 'Command ID',
          description: 'The id of the command to run',
          actions: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: commandIdController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (text) {
                  commandId = text;
                  updateSettings();
                },
              ),
            )
          ],
        ),
        SettingsItem(
          name: 'Metadata',
          description: 'The metdata passed to the command',
        ),
        TextField(
          controller: metadataController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: null,
          onChanged: (text) {
            metadata = text;
            updateSettings();
          },
        ),
      ],
    );
  }
}
