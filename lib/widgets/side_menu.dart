import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    required this.db,
  }) : super(key: key);

  final Database db;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: EdgeInsets.only(
          top: kIsWeb ? Theme.of(context).own().kDefaultPadding : 0),
      color: Theme.of(context).own().kBgLightColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: Theme.of(context).own().kDefaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Fleeting Notes",
                    ),
                  ),
                  if (!Responsive.isDesktop(context)) const CloseButton(),
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
