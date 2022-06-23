import 'dart:async';
import 'package:fleeting_notes_flutter/db/firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:hive_flutter/adapters.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState<T extends StatefulWidget> extends State<MyApp> {
  Note? initNote;
  final Database db = Database(firebase: FirebaseDB());
  Future<Note?> navigateScreen(String? noteId) async {
    await db.firebase.userChanges.first;
    if (noteId == null) return null;
    Note? note = await db.getNote(noteId);
    note ??= await db.firebase.getNoteById(noteId);
    if (note != null && note.partition.isNotEmpty) {
      db.firebase.userId = note.partition;
    }
    return note;
  }

  void refreshApp(user) {
    if (user != null) {
      db.getAllNotes(forceSync: true);
    }
    db.popAllRoutes();
    db.searchKey = GlobalKey();
    db.noteHistory = {Note.empty(): GlobalKey()};
  }

  @override
  void initState() {
    super.initState();
    db.firebase.authChangeController.stream.listen(refreshApp);
    if (kIsWeb) {
      setState(() {
        initNote = db.getUnsavedNote();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    db.firebase.authChangeController.close();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => FutureBuilder<Note?>(
            future: navigateScreen(state.queryParams['note']),
            builder: (BuildContext context, AsyncSnapshot<Note?> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (!snapshot.hasData &&
                    state.queryParams['note'] != null &&
                    state.path == '/') {
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
                  db: db,
                  initNote:
                      (snapshot.hasData) ? snapshot.data as Note : initNote,
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, _) => SettingsScreen(db: db),
            ),
          ],
        ),
      ],
    );
    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(keys: ['darkMode']),
        builder: (context, Box box, _) {
          return MaterialApp.router(
            title: 'Fleeting Notes',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: box.get('darkMode', defaultValue: false)
                ? ThemeMode.dark
                : ThemeMode.light,
            routeInformationProvider: _router.routeInformationProvider,
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
          );
        });
  }
}
