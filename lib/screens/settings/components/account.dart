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
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingItem(
            title: 'Email',
            description: email,
            buttonLabel: 'Logout',
            onPress: onLogout,
          ),
          SettingItem(
            title: 'Force Sync',
            description: 'Sync notes from the cloud to the device',
            buttonLabel: 'Force Sync',
            onPress: onForceSync,
          ),
          SettingItem(
            title: 'End-to-end Encryption',
            description: 'Encrypt notes with end-to-end encryption',
            buttonLabel: (onEnableEncryption == null) ? 'Enabled' : 'Enable',
            onPress: onEnableEncryption,
          ),
          SettingItem(
            title: 'Delete Account',
            description: 'Delete your account and all your notes',
            buttonLabel: 'Delete',
            onPress: () {
              showDialog(
                context: context,
                builder: (context) =>
                    DeleteAccountWidget(onDelete: onDeleteAccount),
              );
            },
          )
        ],
      ),
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

class SettingItem extends StatelessWidget {
  const SettingItem({
    Key? key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPress,
  }) : super(key: key);

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(description),
              ],
            ),
          ),
        ),
        ElevatedButton(onPressed: onPress, child: Text(buttonLabel))
      ]),
    );
  }
}
