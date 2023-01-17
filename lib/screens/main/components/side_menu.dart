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
    // final db = ref.watch(dbProvider);
    // bool darkMode = settings.get('dark-mode', defaultValue: false);
    return SizedBox(
      width: width,
      child: NavigationDrawer(
        children: [
          Padding(
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
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FloatingActionButton.extended(
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                    onPressed: addNote,
                    label: const Text('Add Note'),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const NavigationDrawerDestination(
              icon: Icon(Icons.home), label: Text('Home')),
          const SizedBox(height: 8),
          const NavigationDrawerDestination(
              icon: Icon(Icons.settings), label: Text('Settings')),
          const Spacer(),
        ],
      ),
    );
  }
}
