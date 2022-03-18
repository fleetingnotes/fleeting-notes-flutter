import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/components/side_menu.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.db}) : super(key: key);

  final RealmDB db;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.db.scaffoldKey,
      drawer: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: SideMenu(db: widget.db),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add note',
        onPressed: () {
          widget.db.navigateToNote(Note.empty());
        },
      ),
      body: Responsive(
        mobile: SearchScreenNavigator(db: widget.db),
        tablet: Row(
          children: [
            Expanded(
              flex: 6,
              child: SearchScreen(db: widget.db),
            ),
            Expanded(
              flex: 9,
              child: NoteScreenNavigator(db: widget.db, note: Note.empty()),
            ),
          ],
        ),
        desktop: Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchScreen(db: widget.db),
            ),
            Expanded(
              flex: 9,
              child: NoteScreenNavigator(db: widget.db, note: Note.empty()),
            ),
          ],
        ),
      ),
    );
  }
}
