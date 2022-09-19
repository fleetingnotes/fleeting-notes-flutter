import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';

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
    return Padding(
      padding: EdgeInsets.all(Theme.of(context).custom.kDefaultPadding / 2),
      child: Row(children: [
        DropdownButton(
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
        const Spacer(),
        ElevatedButton(
            onPressed: (backupOption) == 'Markdown' ? onImportPress : null,
            child: const Text('Import')),
        const SizedBox(width: 5),
        ElevatedButton(onPressed: onExportPress, child: const Text('Export')),
      ]),
    );
  }
}
