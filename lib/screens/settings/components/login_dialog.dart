import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({
    Key? key,
    required this.onContinue,
    required this.onSeePricing,
  }) : super(key: key);

  final VoidCallback onContinue;
  final VoidCallback onSeePricing;

  List<Widget> getActionButtons() {
    if (!kIsWeb) {
      return [
        ElevatedButton(
          child: const Text('Continue'),
          onPressed: onContinue,
        ),
      ];
    } else {
      return [
        TextButton(
          child: const Text('Continue'),
          onPressed: onContinue,
        ),
        ElevatedButton(
          child: const Text('See Pricing'),
          onPressed: onSeePricing,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout of all other sessions'),
      content: const Text(
          'As a free user, you can only log in with one account at a time.'),
      actions: getActionButtons(),
    );
  }
}
