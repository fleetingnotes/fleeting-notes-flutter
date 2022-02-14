import 'package:flutter/material.dart';
import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/main/components/list_of_notes.dart';
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
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey,
      drawer: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: SideMenu(db: widget.db),
      ),
      body: Responsive(
        mobile: ListOfNotes(
          query: '',
          db: widget.db,
          openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        tablet: Row(
          children: [
            Expanded(
              flex: 6,
              child: ListOfNotes(
                query: '',
                db: widget.db,
                openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            Expanded(
              flex: 9,
              child: NoteScreenNavigator(db: widget.db),
            ),
          ],
        ),
        desktop: Row(
          children: [
            // Expanded(
            //   flex: 3,
            //   child: SideMenu(db: widget.db),
            // ),
            Expanded(
              flex: 3,
              child: ListOfNotes(
                query: '',
                db: widget.db,
                openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            Expanded(
              flex: 9,
              child: NoteScreenNavigator(db: widget.db),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteScreenNavigator extends StatelessWidget {
  const NoteScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) => NoteScreen(
          note: Note(
            id: '0123',
            title: 'i am title',
            content: 'i am content',
          ),
          db: db,
        ),
      ),
    );
  }
}
