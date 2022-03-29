import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

class MockRealmDB extends Mock implements RealmDB {
  @override
  final GlobalKey searchKey = GlobalKey();
  @override
  Map<Note, GlobalKey> noteHistory = {Note.empty(): GlobalKey()};
  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController streamController = StreamController();

  // not ideal that i have to copy below from the real class
  @override
  void navigateToNote(Note note) {
    GlobalKey noteKey = GlobalKey();
    noteHistory[note] = noteKey;
    navigatorKey.currentState!.push(
      PageRouteBuilder(
          pageBuilder: (context, _, __) => NoteEditor(db: this, note: note)),
    );
  }

  @override
  void navigateToSearch(String query) {
    navigatorKey.currentState!.push(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => SearchScreen(db: this),
        transitionsBuilder: _transitionBuilder,
      ),
    );
  }

  SlideTransition _transitionBuilder(
      context, animation, secondaryAnimation, child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  @override
  void listenNoteChange(Function callback) {
    unlistenNoteChange();
    Stream stream = streamController.stream;
    stream.listen((note) {
      callback(note);
    });
  }

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
