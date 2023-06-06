import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsItemSwitch extends ConsumerWidget {
  const SettingsItemSwitch({
    super.key,
    required this.settingsKey,
    this.name = '',
    this.description = '',
    this.defaultValue = false,
  });

  final String settingsKey;
  final String name;
  final String description;
  final bool defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ValueListenableBuilder(
      valueListenable: settings.box.listenable(keys: [settingsKey]),
      builder: (context, Box box, _) {
        return SettingsItem(
          name: name,
          description: description,
          actions: [
            Switch(
                value: settings.get(settingsKey, defaultValue: defaultValue),
                onChanged: (v) => settings.set(settingsKey, v))
          ],
        );
      },
    );
  }
}
