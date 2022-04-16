import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:hive/hive.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    required this.db,
  }) : super(key: key);

  final Database db;

  @override
  Widget build(BuildContext context) {
    bool darkMode = Hive.box('settings').get('darkMode', defaultValue: false);
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
                      Hive.box('settings').put('darkMode', !darkMode);
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
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
