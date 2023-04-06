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

class PasteIntent extends Intent {
  const PasteIntent();
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

Map<LogicalKeySet, Intent> shortcutMapping = <LogicalKeySet, Intent>{
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
      const NewNoteIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyO):
      const NewNoteIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
      const SearchIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
      const SearchIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
      const SaveIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
      const SaveIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
      const PasteIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
      const BoldIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
      const BoldIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI):
      const ItalicIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
      const ItalicIntent(),
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
      const AddLinkIntent(),
  LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
      const AddLinkIntent(),
};
