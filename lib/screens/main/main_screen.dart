import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/side_menu.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen_navigator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key, required this.db, this.initNote})
      : super(key: key);

  final Database db;
  final Note? initNote;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    if (widget.initNote == null) {
      widget.db.noteHistory = {Note.empty(): GlobalKey()};
    } else {
      widget.db.noteHistory = {widget.initNote!: GlobalKey()};
    }
    super.initState();
  }

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
          // This is bugged because floating action button isn't part of
          // any route...
          // Provider.of<NoteStackModel>(context, listen: false)
          //     .pushNote(Note.empty());
          widget.db.navigateToNote(Note.empty()); // TODO: Deprecate
          FirebaseAnalytics.instance.logEvent(name: 'click_new_note_fab');
        },
      ),
      body: Responsive(
        mobile: SearchScreenNavigator(db: widget.db),
        tablet: Row(
          children: [
            Expanded(
              flex: 6,
              child: SearchScreen(key: widget.db.searchKey, db: widget.db),
            ),
            Expanded(
              flex: 9,
              child: NoteScreenNavigator(db: widget.db),
            ),
          ],
        ),
        desktop: Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchScreen(key: widget.db.searchKey, db: widget.db),
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
