import 'package:fleeting_notes_flutter/screens/main/components/note_fab.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void onDestinationSelected(BuildContext context, int v) {
  if (v == 0) {
    context.goNamed('home');
  } else if (v == 1) {
    showDialog(
      context: context,
      builder: (context) => const DynamicDialog(child: SettingsScreen()),
    );
  }
}

class SideRail extends StatelessWidget {
  const SideRail({
    Key? key,
    required this.addNote,
    required this.onMenu,
  }) : super(key: key);

  final VoidCallback addNote;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      onDestinationSelected: (v) => onDestinationSelected(context, v),
      leading: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
          ),
          NoteFAB(onPressed: addNote),
        ],
      ),
      groupAlignment: 0,
      labelType: NavigationRailLabelType.all,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
        NavigationRailDestination(
            icon: Icon(Icons.settings), label: Text('Settings'))
      ],
      selectedIndex: 0,
    );
  }
}
