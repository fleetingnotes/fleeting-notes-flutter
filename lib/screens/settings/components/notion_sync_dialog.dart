import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class NotionDialog extends StatefulWidget {
  const NotionDialog({
    Key? key,
    required this.setNotionCredentials,
  }) : super(key: key);

  final Function setNotionCredentials;

  @override
  State<NotionDialog> createState() => _NotionDialogState();
}

class _NotionDialogState extends State<NotionDialog> {
  String errMessage = '';
  TextEditingController tokenController = TextEditingController();
  TextEditingController databaseIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void onSubmit() async {
    try {
      await widget.setNotionCredentials(
          tokenController.text, databaseIdController.text);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        if (e is FleetingNotesException) {
          errMessage = e.message;
        } else {
          errMessage = 'Invalid integration token';
        }
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set up Notion integration'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Create a new integration ',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'here',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch(
                              'https://www.notion.so/my-integrations');
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Enter your integration token',
                  border: OutlineInputBorder(),
                ),
                validator: (_) => (errMessage.isEmpty) ? null : errMessage,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: databaseIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter database ID (found in page URL after ".so/")',
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
