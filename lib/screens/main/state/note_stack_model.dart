import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/auth/auth_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

class NoteStackModel extends ChangeNotifier {
  final List<Note> _notes = [];
  final LinkedHashMap<Note, GlobalKey> _noteHistory =
      LinkedHashMap<Note, GlobalKey>.from({Note.empty(): GlobalKey()});
  GlobalKey<NavigatorState> _noteNavState = GlobalKey<NavigatorState>();

  List<Note> get allNoteHistory => _noteHistory.keys.toList();
  Note get currentNote => allNoteHistory.last;

  set noteNavigator(GlobalKey<NavigatorState> key) {
    _noteNavState = key;
  }

  GlobalKey<NavigatorState> get nav => _noteNavState;

  NavigatorState? getNoteNavigator() => _noteNavState.currentState;

  void addNote(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void removeAllNotes() {
    _notes.clear();
    notifyListeners();
  }

  void pushNote(Note note) {
    GlobalKey noteKey = GlobalKey();
    _noteHistory[note] = noteKey;
    notifyListeners();
  }

  void clearHistory() {
    _noteHistory.clear();
    notifyListeners();
  }
}
