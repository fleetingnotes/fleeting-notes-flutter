import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_title.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_textfield.dart';
import 'package:intl/intl.dart';

class ToolbarSettings extends ConsumerStatefulWidget {
  const ToolbarSettings({
    Key? key,
    this.dateController,
  }) : super(key: key);
  final TextEditingController? dateController;

  @override
  _ToolbarSettingsState createState() => _ToolbarSettingsState();
}

class _ToolbarSettingsState extends ConsumerState<ToolbarSettings> {
  String currentDateformat = "";
  TextEditingController dateController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // Initialize the currentDateformat
    final settings = ref.read(settingsProvider);
    currentDateformat = _isDateFormatValid(
        settings.get('date-format', defaultValue: 'MM/dd/yyyy'));
  }

  String _isDateFormatValid(String value) {
    try {
      var date = DateFormat(value).format(DateTime.now());
      return date.toString();
    } catch (e) {
      return 'null';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsTitle(title: "Toolbar Settings"),
        SettingsItemTextField(
            name: "Date Format",
            description: "Current syntax looks like: $currentDateformat",
            settingsKey: 'date-format',
            hintText: 'MM/dd/yyyy',
            onChanged: (value) {
              // Update the currentDateformat whenever the text changes
              setState(() {
                if (value.isEmpty) {
                  value = 'MM/dd/yyyy';
                }
                currentDateformat = _isDateFormatValid(value);
                if (currentDateformat != 'null') {
                  ref.read(settingsProvider).set('date-format', value);
                }
              });
            },
            controller: dateController),
      ],
    );
  }
}
