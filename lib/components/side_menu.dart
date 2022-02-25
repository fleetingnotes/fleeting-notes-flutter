import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fleeting_notes_flutter/constants.dart';
import 'package:fleeting_notes_flutter/screens/auth/auth_screen.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/responsive.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.only(top: kIsWeb ? kDefaultPadding : 0),
      color: kBgLightColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  const Text("Fleeting Notes"),
                  const Spacer(),
                  if (!Responsive.isDesktop(context)) const CloseButton(),
                ],
              ),
              const Spacer(),
              ListTile(
                title: const Text("Logout"),
                leading: const Icon(Icons.logout),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthScreen(db: db),
                    ),
                  );
                  db.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
