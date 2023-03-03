import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:flutter/material.dart';

class Backup extends StatelessWidget {
  const Backup({
    Key? key,
    required this.backupOption,
    required this.onImportPress,
    required this.onExportPress,
    required this.onBackupOptionChange,
  }) : super(key: key);

  final String backupOption;
  final VoidCallback onImportPress;
  final VoidCallback onExportPress;
  final void Function(String?) onBackupOptionChange;

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      leading: DropdownButton(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        underline: const SizedBox(),
        value: backupOption,
        onChanged: onBackupOptionChange,
        items: const [
          DropdownMenuItem(
            child: Text('Markdown'),
            value: 'Markdown',
          ),
          DropdownMenuItem(
            child: Text('JSON'),
            value: 'JSON',
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: (backupOption) == 'Markdown' ? onImportPress : null,
            child: const Text('Import')),
        ElevatedButton(onPressed: onExportPress, child: const Text('Export')),
      ],
    );
  }
}
