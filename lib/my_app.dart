import 'dart:async';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/syncterface.dart';

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
  StreamController<NoteEvent>? noteChangeController;
  StreamController<NoteEvent>? localFileSyncController;

  void refreshApp(User? user) {
    final db = ref.read(dbProvider);
    if (user != null) {
      db.getAllNotes(forceSync: true);
    }
    db.refreshApp();
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

    authChangeController?.stream.listen(refreshApp);
    refreshApp(db.supabase.currUser);
    if (kIsWeb) {
      setState(() {
        initNote = db.settings.get('unsaved-note');
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    authSubscription?.cancel();
    authChangeController?.close();
    pasteController?.close();
    noteChangeController?.close();
    localFileSyncController?.close();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final _router = GoRouter(
      redirect: (state) {
        if (state.subloc == '/' || state.subloc == '/settings') {
          return null;
        }
        final String _queryString = Uri(
            queryParameters: state.queryParams
                .map((key, value) => MapEntry(key, value.toString()))).query;
        return (_queryString.isEmpty) ? '/' : '/?$_queryString';
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => LoadMainScreen(
            initNote: initNote,
            state: state,
          ),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
    return ValueListenableBuilder(
        valueListenable: db.settings.box.listenable(keys: ['dark-mode']),
        builder: (context, Box box, _) {
          return MaterialApp.router(
            title: 'Fleeting Notes',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: box.get('dark-mode', defaultValue: false)
                ? ThemeMode.dark
                : ThemeMode.light,
            routeInformationProvider: _router.routeInformationProvider,
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
          );
        });
  }
}

class LoadMainScreen extends ConsumerStatefulWidget {
  const LoadMainScreen({
    Key? key,
    required this.initNote,
    required this.state,
  }) : super(key: key);

  final Note? initNote;
  final GoRouterState state;

  @override
  ConsumerState<LoadMainScreen> createState() => _LoadMainScreenState();
}

class _LoadMainScreenState extends ConsumerState<LoadMainScreen> {
  late final Future<Note?> loadFuture;

  @override
  void initState() {
    super.initState();
    loadFuture = loadInitNote();
  }

  Future<Note?> loadInitNote() async {
    Map params = widget.state.queryParams;
    bool paramContains =
        ['title', 'content', 'source'].any((key) => params.containsKey(key));
    Note? newNote;
    if (params['note'] != null) {
      return await getNoteFromId(params['note']);
    } else if (paramContains) {
      newNote = Note.empty(
        title: params['title'] ?? '',
        content: params['content'] ?? '',
        source: params['source'] ?? '',
      );
    } else {
      final be = ref.read(browserExtensionProvider);
      String selectionText = await be.getSelectionText();
      if (selectionText.isNotEmpty) {
        String sourceUrl = await be.getSourceUrl();
        newNote = Note.empty(content: selectionText, source: sourceUrl);
      }
    }
    return (newNote == null || newNote.isEmpty()) ? null : newNote;
  }

  Future<Note?> getNoteFromId(String noteId) async {
    final db = ref.read(dbProvider);
    Note? note = await db.getNote(noteId);
    note ??= await db.supabase.getNoteById(noteId);
    if (note != null && note.partition.isNotEmpty) {
      db.shareUserId = note.partition;
    }
    return note;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note?>(
      future: loadFuture,
      builder: (BuildContext context, AsyncSnapshot<Note?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (!snapshot.hasData &&
              widget.state.queryParams['note'] != null &&
              widget.state.path == '/') {
            Future.delayed(Duration.zero, () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: const Text('Note not found'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Ok'),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/');
                        },
                      ),
                    ],
                  );
                },
              );
            });
          }
          return MainScreen(
            initNote:
                (snapshot.hasData) ? snapshot.data as Note : widget.initNote,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
