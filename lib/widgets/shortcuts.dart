import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewNoteIntent extends Intent {
  const NewNoteIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class BacklinkIntent extends Intent {
  const BacklinkIntent();
}

class TagIntent extends Intent {
  const TagIntent();
}

class BoldIntent extends Intent {
  const BoldIntent();
}

class ItalicIntent extends Intent {
  const ItalicIntent();
}

class AddLinkIntent extends Intent {
  const AddLinkIntent();
}

class ListIntent extends Intent {
  const ListIntent();
}

class CheckboxIntent extends Intent {
  const CheckboxIntent();
}

Map<SingleActivator, Intent> mainShortcutMapping = <SingleActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyO, meta: true): const NewNoteIntent(),
  SingleActivator(LogicalKeyboardKey.keyO, control: true):
      const NewNoteIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true): const SearchIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, control: true): const SearchIntent(),
};

Map<SingleActivator, Intent> noteShortcutMapping = <SingleActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyS, meta: true): const SaveIntent(),
  SingleActivator(LogicalKeyboardKey.keyS, control: true): const SaveIntent(),
  SingleActivator(LogicalKeyboardKey.keyB, meta: true): const BoldIntent(),
  SingleActivator(LogicalKeyboardKey.keyB, control: true): const BoldIntent(),
  SingleActivator(LogicalKeyboardKey.keyI, meta: true): const ItalicIntent(),
  SingleActivator(LogicalKeyboardKey.keyI, control: true): const ItalicIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true): const AddLinkIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, control: true):
      const AddLinkIntent(),
};
