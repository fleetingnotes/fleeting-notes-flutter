import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void onSetting(BuildContext context) {
  context.goNamed('settings');
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          IconButton(onPressed: onMenu, icon: const Icon(Icons.menu)),
          const Spacer(),
          IconButton(
            onPressed: () => onSetting(context),
            icon: const Icon(Icons.settings),
          ),
          Text('Settings', style: Theme.of(context).textTheme.labelSmall)
        ],
      ),
    );
  }
}
