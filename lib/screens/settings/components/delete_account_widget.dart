import 'package:flutter/material.dart';

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
