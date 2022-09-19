import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:go_router/go_router.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    required this.db,
  }) : super(key: key);

  final Database db;

  @override
  Widget build(BuildContext context) {
    bool darkMode = db.settings.get('dark-mode', defaultValue: false);
    return Container(
      height: double.infinity,
      padding: EdgeInsets.only(
          top: kIsWeb ? Theme.of(context).custom.kDefaultPadding : 0),
      color: Theme.of(context).dialogBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Theme.of(context).custom.kDefaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Fleeting Notes",
                    ),
                  ),
                  IconButton(
                    icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
                    onPressed: () {
                      db.settings.set('dark-mode', !darkMode);
                    },
                    tooltip: 'Toggle Theme',
                  )
                ],
              ),
              const Spacer(),
              ListTile(
                title: const Text("Settings"),
                leading: const Icon(Icons.settings),
                onTap: () {
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
