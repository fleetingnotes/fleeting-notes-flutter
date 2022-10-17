import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/note/note_editor.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSettings extends Mock implements Settings {
  @override
  get(String key, {defaultValue}) {
    Map<String, dynamic> testSettings = {
      "auto-fill-source": false,
      "analytics-enabled": true,
      "save-delay-ms": 1000,
      "max-attachment-size-mb": 1,
      "max-attachment-size-mb-premium": 1,
      "initial-notes": [],
    };
    return testSettings[key] ?? defaultValue;
  }

  @override
  Future<void> set(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  bool isFirstTimeOpen() => false;
}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseDB extends Mock implements SupabaseDB {
  @override
  Future<String?> getEncryptionKey() async => null;

  @override
  SupabaseClient client = MockSupabaseClient();
}

class MockDatabase extends Mock implements Database {
  @override
  Settings settings = MockSettings();
  @override
  final GlobalKey searchKey = GlobalKey();
  @override
  Map<Note, GlobalKey> noteHistory = {Note.empty(): GlobalKey()};
  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  StreamController streamController = StreamController();
  @override
  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  @override
  SupabaseDB supabase = MockSupabaseDB();

  @override
  Future<bool> noteExists(Note note) async => true;

  // not ideal that i have to copy below from the real class
  @override
  void navigateToNote(Note note, {bool isShared = false}) {
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
  Future<StreamSubscription> listenNoteChange(Function callback) async {
    unlistenNoteChange();
    Stream stream = streamController.stream;
    return stream.listen((note) {
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
