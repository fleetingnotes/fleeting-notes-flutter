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
  const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
      const NewNoteIntent(),
  const SingleActivator(LogicalKeyboardKey.keyO, control: true):
      const NewNoteIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
      const SearchIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, control: true):
      const SearchIntent(),
};

Map<SingleActivator, Intent> noteShortcutMapping = <SingleActivator, Intent>{
  const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
      const SaveIntent(),
  const SingleActivator(LogicalKeyboardKey.keyS, control: true):
      const SaveIntent(),
  const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
      const BoldIntent(),
  const SingleActivator(LogicalKeyboardKey.keyB, control: true):
      const BoldIntent(),
  const SingleActivator(LogicalKeyboardKey.keyI, meta: true):
      const ItalicIntent(),
  const SingleActivator(LogicalKeyboardKey.keyI, control: true):
      const ItalicIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
      const AddLinkIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, control: true):
      const AddLinkIntent(),
};
