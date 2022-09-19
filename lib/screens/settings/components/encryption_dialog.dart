import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:flutter/material.dart';

class EncryptionDialog extends StatefulWidget {
  const EncryptionDialog({
    Key? key,
    required this.setEncryptionKey,
  }) : super(key: key);

  final Function setEncryptionKey;

  @override
  State<EncryptionDialog> createState() => _EncryptionDialogState();
}

class _EncryptionDialogState extends State<EncryptionDialog> {
  String errMessage = '';
  TextEditingController controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void onSubmit() async {
    try {
      await widget.setEncryptionKey(controller.text);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        if (e is FleetingNotesException) {
          errMessage = e.message;
        } else {
          errMessage = 'Invalid encryption key';
        }
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enable Encryption'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This password cannot be changed later'),
              const Text(
                  'If you forget this password, data will remain unusable forever',
                  style: TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Enter your encryption key',
                  border: OutlineInputBorder(),
                ),
                validator: (_) => (errMessage.isEmpty) ? null : errMessage,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSubmit,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
