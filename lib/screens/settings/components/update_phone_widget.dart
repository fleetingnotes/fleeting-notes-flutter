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
  String? phoneErrorText;
  String? codeErrorText;
  bool codeSent = false;
  final _phoneNumberController =
      TextEditingController(text: '+1'); // Initialize with +1
  final _verificationCodeController = TextEditingController();
  bool get validPhoneNumber =>
      _phoneNumberController.text.startsWith('+') &&
      _phoneNumberController.text.length > 11;

  Future<void> _updatePhoneNumber() async {
    final phoneNumber = _phoneNumberController.text;
    final supabase = ref.read(supabaseProvider);
    try {
      await supabase.client.auth.updateUser(UserAttributes(phone: phoneNumber));
      setState(() {
        codeSent = true;
      });
    } on AuthException catch (e) {
      setState(() {
        phoneErrorText = e.message;
      });
    }
  }

  Future<void> _verifyNumber() async {
    final supabase = ref.read(supabaseProvider);
    try {
      await supabase.client.auth.verifyOTP(
        phone: _phoneNumberController.text,
        token: _verificationCodeController.text,
        type: OtpType.phoneChange,
      );
      Navigator.of(context).pop();
      widget.onPhoneUpdated?.call();
      setState(() {
        codeSent = false;
      });
    } on AuthException catch (e) {
      setState(() {
        codeErrorText = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: InputDecoration(
              labelText: 'Cellphone Number',
              hintText: 'Enter your cellphone number (e.g. +1XXXXXXXXXX)',
              errorText: phoneErrorText,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (_) => setState(() {
              codeSent = false;
            }),
          ),
          if (codeSent)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _verificationCodeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter the code sent to your phone',
                  errorText: codeErrorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        (!codeSent)
            ? ElevatedButton(
                onPressed: validPhoneNumber ? _updatePhoneNumber : null,
                child: const Text('Update Number'),
              )
            : ElevatedButton(
                onPressed: _verifyNumber, child: const Text('Verify')),
      ],
    );
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }
}
