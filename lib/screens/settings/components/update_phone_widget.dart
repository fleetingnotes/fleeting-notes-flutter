import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePhoneWidget extends ConsumerStatefulWidget {
  const UpdatePhoneWidget({
    Key? key,
    this.onPhoneUpdated,
  }) : super(key: key);

  final VoidCallback? onPhoneUpdated;

  @override
  ConsumerState<UpdatePhoneWidget> createState() => _UpdatePhoneWidgetState();
}

class _UpdatePhoneWidgetState extends ConsumerState<UpdatePhoneWidget> {
  String phoneNumber = '+1';
  final _phoneNumberController =
      TextEditingController(text: '+1'); // Initialize with +1

  bool _isValidPhoneNumber() {
    // Basic validation to check if the phone number starts with a '+' and has at least 10 more characters
    return phoneNumber.startsWith('+') && phoneNumber.length > 11;
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseProvider);
    return AlertDialog(
      title: const Text('Update phone number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Setting a phone number is requrired to create notes from texts and calls. You will be notified if a note has not been saved.'),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneNumberController,
            autofillHints: const [AutofillHints.telephoneNumber],
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Cellphone Number',
              hintText: 'Enter your cellphone number (e.g. +1XXXXXXXXXX)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (val) {
              setState(() {
                phoneNumber = val;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValidPhoneNumber()
              ? () async {
                  Navigator.pop(context);
                  await supabase.client.auth
                      .updateUser(UserAttributes(phone: phoneNumber));
                  widget.onPhoneUpdated?.call();
                }
              : null,
          child: const Text('Update Number'),
        ),
      ],
    );
  }
}
