import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleeting_notes_flutter/db/firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late final StreamSubscription userChanges;
  Future<String> navigateScreen() async {
    await db.firebase.userChanges.first;
    return 'main';
  }

  void refreshApp() {
    db.popAllRoutes();
    setState(() {
      db.searchKey = GlobalKey();
      db.noteHistory = {Note.empty(): GlobalKey()};
    });
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      setState(() {
        initNote = db.getUnsavedNote();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    userChanges.cancel();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(keys: ['darkMode']),
        builder: (context, Box box, _) {
          return MaterialApp(
            title: 'Fleeting Notes',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: box.get('darkMode', defaultValue: false)
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => FutureBuilder<String>(
                    future: navigateScreen(),
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      if (snapshot.hasData) {
                        return MainScreen(
                          db: db,
                          initNote: initNote,
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
              '/settings': (context) =>
                  SettingsScreen(db: db, refreshApp: refreshApp),
            },
          );
        });
  }
}
