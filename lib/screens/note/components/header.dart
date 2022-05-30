import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.onSave,
    required this.onDelete,
    required this.onSearch,
    required this.analytics,
    this.title = '',
  }) : super(key: key);

  final Function? onSave;
  final VoidCallback onDelete;
  final VoidCallback onSearch;
  final FirebaseAnalytics analytics;
  final String title;

  void _onBack(context) {
    analytics.logEvent(name: 'go_back_notecard');
    Navigator.of(context).pop();
  }

  void newSave(context) async {
    if (onSave == null) return;
    String errMessage = await onSave!();
    analytics.logEvent(name: 'click_save_note');
    if (errMessage != '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMessage),
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Theme.of(context).custom.kDefaultPadding / 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                (Navigator.canPop(context)) ? () => _onBack(context) : null,
          ),
          SizedBox(width: Theme.of(context).custom.kDefaultPadding / 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: onSave == null ? null : () => newSave(context),
          ),
          if (Responsive.isMobile(context))
            IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text("Delete"),
                onTap: () {
                  analytics.logEvent(name: 'click_delete_note');
                  onDelete();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
