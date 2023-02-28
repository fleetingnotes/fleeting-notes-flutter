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
      child: Drawer(
        // onDestinationSelected: (v) => onDestinationSelected(context, v),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                      'Fleeting Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                    IconButton(
                      onPressed: closeDrawer,
                      icon: const Icon(Icons.menu_open),
                    )
                  ],
                ),
                const Spacer(),
                NavigationButton(
                  icon: const Icon(Icons.settings),
                  label: Text('Settings',
                      style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => onSetting(context),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationButton extends StatelessWidget {
  const NavigationButton(
      {super.key, required this.icon, required this.label, this.onTap});
  final Icon icon;
  final Widget label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            label,
          ],
        ),
      ),
    );
  }
}
