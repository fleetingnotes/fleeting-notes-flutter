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
  final Database db = Database();
  Future<String> navigateScreen() async {
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
                    future: navigateScreen(),
                    builder: (BuildContext context,
                        AsyncSnapshot<String?> snapshot) {
                      if (snapshot.hasData) {
                        return MainScreen(db: db);
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
