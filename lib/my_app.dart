import 'dart:async';
import 'package:fleeting_notes_flutter/screens/note/note_editor_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:fleeting_notes_flutter/widgets/record_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/syncterface.dart';

// private navigators
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => MyAppState();
}

class MyAppState<T extends StatefulWidget> extends ConsumerState<MyApp> {
  Note? initNote;

  Iterable<StreamController> allControllers = [];
  StreamController<AuthChangeEvent?>? authChangeController;
  StreamSubscription? authSubscription;
  StreamController<Uint8List?>? pasteController;
  StreamController? blurController;
  StreamController<NoteEvent>? noteChangeController;
  StreamController<NoteEvent>? localFileSyncController;

  void refreshApp(AuthChangeEvent? event) async {
    final db = ref.read(dbProvider);
    await db.refreshApp(ref);
    router.goNamed('home');
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
    db.initNotes();
  }

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
          name: 'home',
          path: '/',
          redirect: (context, state) {
            var params = state.queryParams;
            var newNote = Note.empty(
              title: params['title'] ?? '',
              content: params['content'] ?? '',
              source: params['source'] ?? '',
            );
            final String _queryString = Uri(
                    queryParameters: state.queryParams
                        .map((key, value) => MapEntry(key, value.toString())))
                .query;
            if (!newNote.isEmpty() && !state.location.startsWith('/note/')) {
              return '/note/${newNote.id}?$_queryString';
            }
            return null;
          },
          builder: (context, state) => const MainScreen(),
          routes: [
            GoRoute(
                name: 'record',
                path: 'note/record',
                pageBuilder: (context, state) {
                  return const DialogPage(child: RecordDialog());
                }),
            GoRoute(
              name: 'note',
              path: 'note/:id',
              redirect: (context, state) {
                var noteId =
                    state.subloc.split('?').first.replaceFirst('/note/', '');
                if (isValidUuid(noteId)) {
                  return null;
                }
                return '/';
              },
              pageBuilder: (context, state) {
                var params = state.queryParams;
                Note? note = state.extra as Note?;
                var noteId =
                    state.subloc.split('?').first.replaceFirst('/note/', '');
                note ??= Note.empty(
                  id: noteId,
                  title: params['title'] ?? '',
                  content: params['content'] ?? '',
                  source: params['source'] ?? '',
                );

                return DialogPage(
                  child: DynamicDialog(
                    child: NoteEditorScreen(
                      noteId: noteId,
                      extraNote: note,
                    ),
                  ),
                );
              },
            ),
          ]),
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
