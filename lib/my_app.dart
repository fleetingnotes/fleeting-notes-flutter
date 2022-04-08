import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/db/database.dart';
import 'package:fleeting_notes_flutter/screens/main/main_screen.dart';
import 'package:fleeting_notes_flutter/screens/settings/settings_screen.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Database db = Database();

  Future<String> _navigateScreen() async {
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
    return MaterialApp(
      title: 'Fleeting Notes',
      // scrollBehavior: MyCustomScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
              .copyWith(background: const Color(0xECECECEC))),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<String>(
              future: _navigateScreen(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
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
  }
}
