import 'package:flutter/material.dart';

class AnalyticsDialog extends StatelessWidget {
  const AnalyticsDialog({
    Key? key,
    required this.onAnalyticsPress,
  }) : super(key: key);

  final Function onAnalyticsPress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: const Text(
            '''Can we collect the following anonymous data about your use of Fleeting Notes:

- Anonymous interaction data, which we collect to make Fleeting Notes better for everyone
- Anonymous crash reports, which we collect to help fix bugs within the app
      
Full details about the anonymous data we collect and what we do with it are provided in our Privacy Policy.'''),
      ),
      actions: [
        TextButton(
            onPressed: () => onAnalyticsPress(true),
            child: const Text("No, don't collect anonymous data")),
        ElevatedButton(
            onPressed: () => onAnalyticsPress(false),
            child: const Text("Yes, collect anonymous data"))
      ],
    );
  }
}
