import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

class MockRealmDB extends Mock implements RealmDB {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  StreamController streamController = StreamController();

  // not ideal that i have to copy below from the real class
  @override
  void navigateToNote(Note note) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
          pageBuilder: (context, _, __) => NoteScreen(db: this, note: note)),
    );
  }

  @override
  void listenNoteChange(Function callback) {
    Stream stream = streamController.stream;
    stream.listen((note) {
      callback(note);
    });
  }

  @override
  void unlistenNoteChange() {
    streamController.close();
    streamController = StreamController();
  }

  @override
  void popAllRoutes() {
    navigatorKey.currentState!.popUntil((route) => false);
  }

  @override
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }
}
