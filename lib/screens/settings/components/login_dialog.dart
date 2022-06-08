import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  final VoidCallback onContinue;

  List<Widget> getActionButtons() {
    String pricingUrl = "https://fleetingnotes.app/pricing?ref=app";
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
          onPressed: () {
            launch(pricingUrl);
          },
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
