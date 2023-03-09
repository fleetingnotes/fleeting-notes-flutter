import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RecoverSessionDialog extends ConsumerWidget {
  const RecoverSessionDialog({
    super.key,
  });

  void onSeePricing() {
    Uri pricingUrl = Uri.parse("https://fleetingnotes.app/pricing?ref=app");
    launchUrl(pricingUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var db = ref.watch(dbProvider);
    return AlertDialog(
      title: const Text("You've been logged out"),
      content: const Text(
          "As a free user, you can only log in with one account at a time."),
      actions: [
        TextButton(
          child: const Text('Continue'),
          onPressed: () {
            db.supabase.clearSession();
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          child: const Text('See Pricing'),
          onPressed: onSeePricing,
        ),
      ],
    );
  }
}
