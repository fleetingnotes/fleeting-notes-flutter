import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Database db = Database();
  Note? initNote;

  @override
  void initState() {
    Note getNoteFromShareText(String sharedText) {
      try {
        bool _validURL = Uri.parse(sharedText).isAbsolute;
        if (_validURL) {
          return Note.empty(source: sharedText);
        } else {
          return Note.empty(content: sharedText);
        }
      } on FormatException {
        return Note.empty(content: sharedText);
      }
    }

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getTextStream().listen((String sharedText) {
      db.navigateToNote(getNoteFromShareText(sharedText), isShared: true);
    }, onError: (err) {
      // ignore: avoid_print
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? sharedText) {
      if (sharedText != null) {
        setState(() {
          initNote = getNoteFromShareText(sharedText);
        });
      }
    });
    super.initState();
  }

  Future<String> _navigateScreen() async {
    await db.loginWithStorage();
    return 'main';
  }

  void refreshScreen() {
    db.popAllRoutes();
    setState(() {
      db.searchKey = GlobalKey();
      db.noteHistory = {Note.empty(): GlobalKey()};
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(),
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
                    future: _navigateScreen(),
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      if (snapshot.hasData) {
                        return MainScreen(db: db, initNote: initNote);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
              '/settings': (context) =>
                  SettingsScreen(db: db, onAuthChange: refreshScreen)
            },
          );
        });
  }
}
