import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/info_card.dart';

class OnboardingDialog extends StatelessWidget {
  final double? width;
  const OnboardingDialog({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Welcome to Fleeting Notes!'),
        content: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: SelectionArea(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                const Text(
                    "Hey, I'm Matt the creator of Fleeting Notes! If you have any questions at all, don't hesitate to email me at: matthew@fleetingnotes.app",
                    textAlign: TextAlign.start),
                const SizedBox(height: 8),
                const Text("Below are some guides to help you get started:",
                    textAlign: TextAlign.start),
                const SizedBox(height: 8),
                InfoCard(
                  title: 'Obsidian Sync (Recommended)',
                  description:
                      'Sync your notes with Obsidian directly. Requires an account & syncs notes through the cloud.',
                  buttonText: 'Read Blog',
                  onPressed: () {
                    Uri url = Uri.parse(
                        "https://www.fleetingnotes.app/posts/sync-fleeting-notes-with-obsidian");
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
                InfoCard(
                  title: 'Local File Sync (Beta)',
                  description:
                      'Syncs your notes to markdown files on your file system',
                  buttonText: 'Read Blog',
                  onPressed: () {
                    Uri url = Uri.parse(
                        "https://www.fleetingnotes.app/posts/how-to-setup-local-file-sync");
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              child: const Text('OK Matt!'),
              onPressed: Navigator.of(context).pop),
        ]);
  }
}
