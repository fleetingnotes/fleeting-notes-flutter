import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/utils/toolbar.dart';

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

  void action(String left, String right, {TextSelection? textSelection}) {
    _toolbar.action(left, right, textSelection: textSelection);
    if (_toolbar.hasSelection) {
      controller.selection = controller.selection.copyWith(
        baseOffset: controller.selection.baseOffset + left.length,
        extentOffset: controller.selection.extentOffset - right.length,
      );
    }
  }

  void addLink() {
    _toolbar.action('[', ']()');
    if (_toolbar.hasSelection) {
      controller.selection = controller.selection.copyWith(
        baseOffset: controller.selection.extentOffset - 1,
        extentOffset: controller.selection.extentOffset - 1,
      );
    }
  }

  void toggleList() {
    _toolbar.startLineAction('- ', replaceLine: (String line) {
      if (line.startsWith('- ')) {
        return line.replaceFirst('- ', '');
      }
      return '- ' + line;
    });
  }

  void toggleCheckbox() {
    _toolbar.startLineAction('- [ ] ', replaceLine: (String line) {
      if (line.startsWith('- [ ] ')) {
        return line.replaceFirst('- [ ] ', '- [x] ');
      } else if (line.startsWith('- [x] ')) {
        return line.replaceFirst('- [x] ', '');
      }
      return '- [ ] ' + line;
    });
  }

  void addListener() {
    TextSelection selection = controller.selection;
    print(selection);
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
        _toolbar.listOnEnter();
        break;
      default:
        break;
    }
  }
}
