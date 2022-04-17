import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/flags.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:hive_flutter/adapters.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Database db = Database();
  final Flags flags = Flags();
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
    // TESTING You would move this elsewhere when you need the flag
    // flags.loadGlobalFlags().then((_) {
    //   print(flags.getFlag<int>("flag_1"));
    //   print(flags.getFlag<bool>("flag_2"));
    //   print(flags.getFlag<String>("flag_3"));
    // });

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
