import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/Note.dart';
import '../models/search_query.dart';
import 'package:fleeting_notes_flutter/models/note_history.dart';

class SearchNotifier extends StateNotifier<SearchQuery?> {
  SearchNotifier() : super(null);

  void updateSearch(SearchQuery? sq) {
    state = sq?.copy();
  }
}

class NoteHistoryNotifier extends StateNotifier<NoteHistory> {
  NoteHistoryNotifier() : super(NoteHistory());

  Note? get currNote => state.currNote;

  void addNote(BuildContext context, Note note) {
    NoteHistory nh = state.copy();
    Note? prevNote = nh.currNote;
    if (GoRouter.of(context).location == '/') {
      nh.backNoteHistory = [];
    }
    if (prevNote != null) {
      nh.backNoteHistory.add(prevNote);
    }
    nh.forwardNoteHistory = [];
    nh.currNote = note;
    context.goNamed('note', params: {'id': note.id}, extra: {'note': note});
    state = nh;
  }

  // returns popped noteId
  Note? goBack(BuildContext context) {
    var nh = state.copy();
    if (nh.backNoteHistory.isEmpty) return goHome(context);
    Note? prevNote = nh.currNote;
    if (prevNote != null) {
      nh.forwardNoteHistory.add(prevNote);
    }
    var note = nh.backNoteHistory.removeLast();
    context.goNamed('note', params: {'id': note.id});
    nh.currNote = note;
    state = nh;
    return prevNote;
  }

  // returns popped noteId
  Note? goForward(BuildContext context) {
    var nh = state.copy();
    if (nh.forwardNoteHistory.isEmpty) return null;
    Note? prevNoteId = nh.currNote;
    if (prevNoteId != null) {
      nh.backNoteHistory.add(prevNoteId);
    }
    var note = nh.forwardNoteHistory.removeLast();
    context.goNamed('note', params: {'id': note.id});
    nh.currNote = note;
    state = nh;
    return prevNoteId;
  }

  // dont notify but update state
  Note? goHome(BuildContext context) {
    context.goNamed('home');
    Note? prevNote = currNote;
    // add delay to avoid jank
    Future.delayed(const Duration(milliseconds: 100), () {
      state = NoteHistory();
    });
    return prevNote;
  }
}
