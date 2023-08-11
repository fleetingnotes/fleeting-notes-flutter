import 'package:fleeting_notes_flutter/screens/note/components/ContentField/keyboard_button.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/utils/shortcut_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToolbarState {
  edit("Edit", Icons.edit),
  markdown("Markdown", Icons.military_tech_sharp),
  tags("Tags", Icons.tag);

  const ToolbarState(this.value, this.icon);
  final String value;
  final IconData icon;
}

class TextFieldToolbar extends ConsumerWidget {
  const TextFieldToolbar({
    Key? key,
    required this.shortcuts,
    required this.controller,
    this.onContentChanged,
    this.unfocus,
  }) : super(key: key);

  final ShortcutActions shortcuts;
  final TextEditingController controller;
  final Function(String)? onContentChanged;
  final VoidCallback? unfocus;

  @override
  build(BuildContext context, WidgetRef ref) {
    final toolbarState = ref.watch(toolbarProvider);
    final editToolbar = [
      PopupMenuButton(
        icon: Icon(toolbarState.icon),
        itemBuilder: (context) => <PopupMenuEntry>[],
        // onPressed: unfocus,
      ),
      const VerticalDivider(),
      Expanded(
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            KeyboardButton(
              icon: Icons.data_array,
              onPressed: () {
                shortcuts.action('[[', ']]');
                onContentChanged?.call(controller.text);
              },
              tooltip: 'Add link',
            ),
            KeyboardButton(
              icon: Icons.tag,
              onPressed: () {
                shortcuts.action('#', '');
                onContentChanged?.call(controller.text);
              },
            ),
            KeyboardButton(
              icon: Icons.format_bold,
              onPressed: () {
                shortcuts.action('**', '**');
                onContentChanged?.call(controller.text);
              },
            ),
            KeyboardButton(
              icon: Icons.format_italic,
              onPressed: () {
                shortcuts.action('*', '*');
                onContentChanged?.call(controller.text);
              },
            ),
            KeyboardButton(
              icon: Icons.add_link,
              onPressed: () {
                shortcuts.addLink();
                onContentChanged?.call(controller.text);
              },
            ),
            KeyboardButton(
              icon: Icons.list,
              onPressed: () {
                shortcuts.toggleList();
                onContentChanged?.call(controller.text);
              },
            ),
            KeyboardButton(
              icon: Icons.checklist_outlined,
              onPressed: () {
                shortcuts.toggleCheckbox();
                onContentChanged?.call(controller.text);
              },
            ),
          ],
        ),
      ),
      const VerticalDivider(),
      KeyboardButton(
        icon: Icons.keyboard_hide,
        onPressed: unfocus,
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [if (toolbarState == ToolbarState.edit) ...editToolbar],
      ),
    );
  }
}
