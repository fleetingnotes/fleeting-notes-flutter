import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/KeyboardActions/toolbar.dart';

class ShortcutActions {
  late final Toolbar _toolbar;
  final TextEditingController controller;
  final VoidCallback? bringEditorToFocus;

  ShortcutActions({required this.controller, this.bringEditorToFocus}) {
    _toolbar =
        Toolbar(controller: controller, bringEditorToFocus: bringEditorToFocus);
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
        return line.replaceFirst('- [ ]', '- [x]');
      } else if (line.startsWith('- [x]')) {
        return line.replaceFirst('- [x]', '- [ ]');
      }
      return '- [ ] ' + line;
    });
  }
}
