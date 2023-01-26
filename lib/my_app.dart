import 'dart:async';
import 'package:fleeting_notes_flutter/screens/note/note_editor_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/syncterface.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState<T extends StatefulWidget> extends ConsumerState<MyApp> {
  Note? initNote;

  Iterable<StreamController> allControllers = [];
  StreamController<User?>? authChangeController;
  StreamSubscription? authSubscription;
  StreamController<Uint8List?>? pasteController;
  StreamController? blurController;
  StreamController<NoteEvent>? noteChangeController;
  StreamController<NoteEvent>? localFileSyncController;

  void refreshApp(User? user) {
    final db = ref.read(dbProvider);
    if (user != null) {
      db.getAllNotes(forceSync: true);
    }
    db.refreshApp(ref);
  }

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    final be = ref.read(browserExtensionProvider);
    final ls = ref.read(localFileSyncProvider);
    noteChangeController = db.noteChangeController;
    localFileSyncController = ls.streamController;
    authChangeController = db.supabase.authChangeController;
    authSubscription = db.supabase.authSubscription;
    pasteController = be.pasteController;
    blurController = be.blurController;
    be.blurController.stream.listen((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    authChangeController?.stream.listen(refreshApp);
    SchedulerBinding.instance
        .addPostFrameCallback((_) => refreshApp(db.supabase.currUser));
  }

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
              name: 'home',
              path: '/',
              builder: (context, state) {
                var params = state.queryParams;
                var newNote = Note.empty(
                  title: params['title'] ?? '',
                  content: params['content'] ?? '',
                  source: params['source'] ?? '',
                );
                return NoteEditorScreen(
                  noteId: newNote.id,
                  extraNote: newNote,
                );
              }),
          GoRoute(
            name: 'note',
            path: '/note/:id',
            redirect: (context, state) {
              var noteId = state.subloc.replaceFirst('/note/', '');
              if (isValidUuid(noteId)) {
                return state.subloc;
              }
              return '/';
            },
            builder: (context, s) {
              Note? note = s.extra as Note?;
              var noteId = note?.id ?? s.subloc.replaceFirst('/note/', '');

              return NoteEditorScreen(
                noteId: noteId,
                extraNote: note,
              );
            },
          ),
          // https://github.com/flutter/flutter/issues/115355
          // redirect will use empty location if below is not present
        ],
      ),
      GoRoute(
        path: '/web-ext.html',
        redirect: (context, state) {
          final String _queryString = Uri(
              queryParameters: state.queryParams
                  .map((key, value) => MapEntry(key, value.toString()))).query;
          return (_queryString.isEmpty) ? '/' : '/?$_queryString';
        },
      ),
    ],
  );

  @override
  void dispose() {
    super.dispose();
    authSubscription?.cancel();
    authChangeController?.close();
    pasteController?.close();
    blurController?.close();
    noteChangeController?.close();
    localFileSyncController?.close();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return ValueListenableBuilder(
        valueListenable: db.settings.box.listenable(keys: ['dark-mode']),
        builder: (context, Box box, _) {
          return MaterialApp.router(
            title: 'Fleeting Notes',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.blue,
              brightness: box.get('dark-mode', defaultValue: false)
                  ? Brightness.dark
                  : Brightness.light,
            ),
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
          );
        });
  }
}
