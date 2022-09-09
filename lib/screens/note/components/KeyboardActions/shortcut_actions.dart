import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/KeyboardActions/toolbar.dart';

class ShortcutActions {
  late String prevText;
  late final Toolbar _toolbar;
  final TextEditingController controller;
  final VoidCallback? bringEditorToFocus;

  ShortcutActions({required this.controller, this.bringEditorToFocus}) {
    _toolbar =
        Toolbar(controller: controller, bringEditorToFocus: bringEditorToFocus);
    prevText = controller.text;
    controller.addListener(addListener);
  }

  void addLink() {
    _toolbar.action('[[', ']]');
  }

  void addTag() {
    _toolbar.insertTextAtCursor('#');
  }

  void toggleCheckbox() {
    _toolbar.startLineAction('- [ ] ', replaceLine: (String line) {
      if (line.startsWith('- [ ]')) {
        return line.replaceFirst('- [ ] ', '- [x] ');
      } else if (line.startsWith('- [x] ')) {
        return line.replaceFirst('- [x] ', '- [ ] ');
      }
      return '- [ ] ' + line;
    });
  }

  void addListener() {
    TextSelection selection = controller.selection;
    if (prevText == controller.text ||
        controller.text.length < prevText.length ||
        selection.start < 1) {
      prevText = controller.text;
      return;
    }
    prevText = controller.text;
    String pressedKey =
        controller.text.substring(selection.start - 1, selection.start);
    switch (pressedKey) {
      case '\n':
        _toolbar.listOnEnter(RegExp(r'^(- \[[ |x]\] |- |\* )'));
        break;
      default:
        break;
    }
  }
}
