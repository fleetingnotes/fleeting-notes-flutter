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
  LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
      const PasteIntent(),
};
