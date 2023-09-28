import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsItemTextField extends ConsumerWidget {
  const SettingsItemTextField({
    Key? key,
    required this.settingsKey,
    this.name = '',
    this.description = '',
    this.defaultValue = '',
    this.hintText = 'Set to set',
    required this.onChanged,
    required this.controller,
  }) : super(key: key);

  final String settingsKey;
  final String name;
  final String description;
  final String defaultValue;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ValueListenableBuilder(
      valueListenable: settings.box.listenable(keys: [settingsKey]),
      builder: (context, Box box, _) {
        String newValue = settings.get(settingsKey, defaultValue: defaultValue);
        if (controller.text != newValue) {
          controller.text = newValue;
        }
        return SettingsItem(
          name: name,
          description: description,
          actions: [
            SizedBox(
              width: 100, // or any other fixed width
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: controller,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: hintText,
                  ),
                  onChanged: (value) {
                    // Set the new value using the settings provider
                    // settings.set(settingsKey, value);

                    // // Call the external onChanged function
                    onChanged(value);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
