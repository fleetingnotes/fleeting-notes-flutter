import 'package:fleeting_notes_flutter/screens/main/components/note_fab.dart';
import 'package:flutter/material.dart';

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
