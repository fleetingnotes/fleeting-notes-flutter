import 'package:fleeting_notes_flutter/screens/settings/components/plugin_command.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';

class PluginCommandSetting extends ConsumerWidget {
  const PluginCommandSetting({
    super.key,
  });

  void upsertSlashCommand(
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
                    onTap: () => upsertSlashCommand(settings),
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
