import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:flutter/material.dart';

class Account extends StatelessWidget {
  const Account({
    Key? key,
    required this.email,
    required this.onLogout,
    required this.onForceSync,
    required this.onDeleteAccount,
    required this.onEnableEncryption,
  }) : super(key: key);

  final String email;
  final VoidCallback onLogout;
  final VoidCallback onForceSync;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEnableEncryption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          name: 'Email',
          description: email,
          actions: [
            ElevatedButton(onPressed: onLogout, child: const Text('Logout'))
          ],
        ),
        SettingsItem(
          name: 'Force Sync',
          description: 'Sync notes from the cloud to the device',
          actions: [
            ElevatedButton(
                onPressed: onForceSync, child: const Text('Force sync'))
          ],
        ),
        SettingsItem(
          name: 'End-to-end Encryption',
          description: 'Encrypt notes with end-to-end encryption',
          actions: [
            ElevatedButton(
                onPressed: onEnableEncryption,
                child:
                    Text((onEnableEncryption == null) ? 'Enabled' : 'Enable'))
          ],
        ),
        SettingsItem(
            name: 'Delete Account',
            description: 'Delete your account and all your notes',
            actions: [
              ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          DeleteAccountWidget(onDelete: onDeleteAccount),
                    );
                  },
                  child: const Text('Delete')),
            ])
      ],
    );
  }
}

class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  final VoidCallback onDelete;

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  bool canDeleteAccount = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Are you sure you want to delete your account and all your notes? This action cannot be undone.'),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Type "delete" to confirm',
              border: OutlineInputBorder(),
            ),
            validator: (_) => 'Type delete to confirm',
            onChanged: (String? value) {
              setState(() {
                canDeleteAccount = value == 'delete';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canDeleteAccount
              ? () {
                  Navigator.pop(context);
                  widget.onDelete();
                }
              : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
