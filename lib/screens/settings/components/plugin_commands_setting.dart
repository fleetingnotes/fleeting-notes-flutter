import 'package:fleeting_notes_flutter/screens/settings/components/plugin_card.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/plugin_command.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_title.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/plugin_selector_dialog.dart';

final List<Plugin> plugins = [
  Plugin(
    key: 'plugin1',
    title: 'ChatGPT',
    description:
        'This plugin passes the content of your note into ChatGPT and also gives you the option to adjust a pre-defined prompt in the metadata.',
    commandId: 'official/chat-gpt-3.5',
  ),
  Plugin(
    key: 'plugin2',
    title: 'Clip Web to Markdown',
    description:
        'This plugin fetches the source of your note and convert it into markdown.',
    commandId: 'official/clip-web-to-md',
  ),
  Plugin(
    key: 'plugin3',
    title: 'Current timestamp',
    description: 'This plugin insert the current timestamp in a note.',
    commandId: 'official/current-timestamp',
  ),
  Plugin(
    key: 'plugin4',
    title: 'OCR source',
    description:
        'This plugin utilizes Google Vision to fetch and convert the source of your image in text.',
    commandId: 'official/ocr-source',
  ),
  Plugin(
    key: 'option3',
    title: 'Speech To Text',
    description:
        'This plugin utilizes Whisper from ChatGPT to fetch and convert the source of your speech.',
    commandId: 'official/speech-to-text',
  ),
  Plugin(
    key: 'plugin5',
    title: 'Summarize Source',
    description:
        'This plugin fetches the source of your note and summarizes it into key points using ChatGPT',
    commandId: 'official/summarize-source',
  ),
];

class PluginCommandSetting extends ConsumerWidget {
  const PluginCommandSetting({
    super.key,
  });

  static void upsertSlashCommand(
    Settings settings, {
    int? index,
    Map<String, String>? commandSettings = const {
      "alias": "",
      "commandId": "",
      "metadata": "",
    },
  }) {
    List allCommands = settings.get('plugin-slash-commands') ?? [];
    if (commandSettings == null && index != null) {
      allCommands.removeAt(index);
    } else {
      if (index == null) {
        allCommands.add(commandSettings);
      } else {
        allCommands[index] = commandSettings;
      }
    }
    settings.set('plugin-slash-commands', allCommands);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const SettingsTitle(title: "Plugin Slash Commands"),
        Card(
          clipBehavior: Clip.hardEdge,
          child: ValueListenableBuilder(
            valueListenable:
                settings.box.listenable(keys: ['plugin-slash-commands']),
            builder: (context, Box box, _) {
              List allCommands = box.get('plugin-slash-commands') ?? [];
              return Column(
                children: [
                  ...allCommands.mapIndexed(
                    (i, commandSettings) => PluginCommandTile(
                      alias: commandSettings['alias'],
                      commandId: commandSettings['commandId'],
                      metadata: commandSettings['metadata'],
                      updateCommandSettings: (newCommandSettings) =>
                          upsertSlashCommand(settings,
                              index: i, commandSettings: newCommandSettings),
                    ),
                  ),
                  ListTile(
                    tileColor: colorScheme.primaryContainer,
                    iconColor: colorScheme.onPrimaryContainer,
                    title: const Text('Add New Command'),
                    leading: const Icon(Icons.add),
                    onTap: () => showDialog(
                      context: context,
                      builder: (c) => PluginSelectorDialog(
                        plugins: plugins,
                        onPluginSelected: (Plugin selectedPlugin) {
                          upsertSlashCommand(
                            settings,
                            index: null,
                            commandSettings: {
                              "alias": selectedPlugin.title,
                              "commandId": selectedPlugin.commandId,
                              "metadata": "",
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
