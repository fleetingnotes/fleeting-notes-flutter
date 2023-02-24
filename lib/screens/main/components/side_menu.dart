import 'package:fleeting_notes_flutter/screens/main/components/side_rail.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    this.addNote,
    this.closeDrawer,
    this.width,
  }) : super(key: key);

  final VoidCallback? addNote;
  final VoidCallback? closeDrawer;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: NavigationDrawer(
        onDestinationSelected: (v) => onDestinationSelected(context, v),
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    'Fleeting Notes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )),
                  IconButton(
                    onPressed: closeDrawer,
                    icon: const Icon(Icons.menu_open),
                  )
                ],
              ),
            ),
          ),
          const NavigationDrawerDestination(
              icon: Icon(Icons.home), label: Text('Home')),
          const SizedBox(height: 8),
          const NavigationDrawerDestination(
              icon: Icon(Icons.settings), label: Text('Settings')),
        ],
      ),
    );
  }
}
