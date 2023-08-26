import 'package:fleeting_notes_flutter/screens/note/components/ContentField/keyboard_button.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/utils/shortcut_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToolbarState {
  edit("Edit", Icons.construction),
  markdown("Markdown", Icons.edit_note_outlined);
  // tags("Tags", Icons.tag);

  const ToolbarState(this.value, this.icon);
  final String value;
  final IconData icon;
}

class TextFieldToolbar extends ConsumerWidget implements PreferredSizeWidget {
  const TextFieldToolbar(
      {Key? key,
      required this.shortcuts,
      required this.controller,
      required this.undoController,
      this.onContentChanged,
      this.onAddAttachment,
      this.focusNode})
      : super(key: key);

  final ShortcutActions shortcuts;
  final TextEditingController controller;
  final UndoHistoryController undoController;
  final FocusNode? focusNode;
  final Function(String)? onContentChanged;
  final VoidCallback? onAddAttachment;

  @override
  Size get preferredSize => const Size.fromHeight(50);

  void _showToolbarMenu(BuildContext context, WidgetRef ref) {
    final toolbarState = ref.read(toolbarProvider);
    final toolbarProviderState = ref.read(toolbarProvider.notifier);
    final RenderBox toolbarBox = context.findRenderObject() as RenderBox;
    final toolbarPosition = toolbarBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    const double menuHeight = 120;
    const double menuWidth = 200;

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Full screen GestureDetector that catches taps outside the menu
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  overlayEntry?.remove();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: toolbarPosition.dx,
              top: toolbarPosition.dy -
                  menuHeight, // Assuming menu height is 200, adjust as necessary
              width: menuWidth,
              child: Material(
                child: SizedBox(
                  height: menuHeight,
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ToolbarState.values.map((state) {
                        return ListTile(
                          enabled: toolbarState != state,
                          onTap: () {
                            // Handle tap, maybe change the state
                            toolbarProviderState.update((_) => state);
                            overlayEntry?.remove();
                          },
                          trailing: Icon(state.icon),
                          title: Text(state.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  @override
  build(BuildContext context, WidgetRef ref) {
    final toolbarState = ref.watch(toolbarProvider);
    final editButtons = [
      KeyboardButton(
        child: const Icon(Icons.undo, size: 20),
        onPressed: () {
          undoController.undo();
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.redo, size: 20),
        onPressed: () {
          undoController.redo();
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.data_array, size: 20),
        onPressed: () {
          shortcuts.action('[[', ']]');
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Text("/", style: TextStyle(fontSize: 20)),
        onPressed: () {
          shortcuts.action('/', '');
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.image_outlined, size: 20),
        onPressed: onAddAttachment,
      ),
    ];
    final mdButtons = [
      KeyboardButton(
        child: const Icon(Icons.tag, size: 20),
        onPressed: () {
          shortcuts.action('#', '');
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.format_bold, size: 20),
        onPressed: () {
          shortcuts.action('**', '**');
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.format_italic, size: 20),
        onPressed: () {
          shortcuts.action('*', '*');
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.add_link, size: 20),
        onPressed: () {
          shortcuts.addLink();
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.list, size: 20),
        onPressed: () {
          shortcuts.toggleList();
          onContentChanged?.call(controller.text);
        },
      ),
      KeyboardButton(
        child: const Icon(Icons.checklist_outlined, size: 20),
        onPressed: () {
          shortcuts.toggleCheckbox();
          onContentChanged?.call(controller.text);
        },
      ),
    ];
    return SizedBox(
      height: preferredSize.height,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: Icon(toolbarState.icon, size: 20),
              onPressed: () => _showToolbarMenu(context, ref)),
          const VerticalDivider(width: 5),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                if (toolbarState == ToolbarState.edit)
                  ...editButtons
                else if (toolbarState == ToolbarState.markdown)
                  ...mdButtons
              ],
            ),
          ),
          const VerticalDivider(width: 5),
          IconButton(
            icon: const Icon(Icons.keyboard_hide, size: 20),
            onPressed: focusNode?.unfocus,
          ),
        ],
      ),
    );
  }
}
