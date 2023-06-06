import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsItemSlider extends ConsumerWidget {
  const SettingsItemSlider({
    super.key,
    required this.settingsKey,
    this.name = '',
    this.description = '',
    this.defaultValue = 1.0,
  });

  final String settingsKey;
  final String name;
  final String description;
  final double defaultValue;

  void onSliderChanged(
    double v,
  ) {}
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Column(
      children: [
        SettingsItem(name: name, description: description),
        ValueListenableBuilder(
          valueListenable: settings.box.listenable(keys: [settingsKey]),
          builder: (context, Box box, _) {
            return Slider(
                value: settings.get(settingsKey, defaultValue: defaultValue),
                label: settings
                    .get(settingsKey, defaultValue: defaultValue)
                    .toString(),
                onChanged: (double v) {
                  settings.set(settingsKey, v);
                },
                min: 0.5,
                max: 1.5,
                divisions: 10);
          },
        ),
      ],
    );
  }
}
