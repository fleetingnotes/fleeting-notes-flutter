import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleeting_notes_flutter/db/firebase.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class MockFirebaseDB extends Mock implements FirebaseDB {
  @override
  FirebaseAnalytics analytics = MockFirebaseAnalytics();
  @override
  FirebaseRemoteConfig remoteConfig = MockRemoteConfig();
  @override
  Stream<User?> get userChanges => const Stream.empty();
}

class MockDatabase extends Mock implements Database {
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
  FirebaseDB firebase = MockFirebaseDB();

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

  @override
  bool fillSource() {
    return false;
  }

  @override
  Future<void> setFillSource(bool autoFillEnabled) async {}

  @override
  bool? getAnalyticsEnabled() {
    return true;
  }
}
