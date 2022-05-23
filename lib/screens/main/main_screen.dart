import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/side_menu.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen_navigator.dart';
import 'package:flutter/scheduler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key, required this.db, this.initNote})
      : super(key: key);

  final Database db;
  final Note? initNote;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  FocusNode searchFocusNode = FocusNode();
  late bool hasInitNote;
  @override
  void initState() {
    super.initState();
    if (widget.initNote == null) {
      hasInitNote = false;
      widget.db.noteHistory = {Note.empty(): GlobalKey()};
    } else {
      hasInitNote = true;
      widget.db.noteHistory = {widget.initNote!: GlobalKey()};
    }
    // Privacy Alert Dialog
    SchedulerBinding.instance.addPostFrameCallback((_) {
      bool? analyticsEnabled = widget.db.getAnalyticsEnabled();
      if (analyticsEnabled == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Privacy'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const Text(
                    '''Can we collect the following anonymous data about your use of Fleeting Notes:

- Anonymous interaction data, which we collect to make Fleeting Notes better for everyone
- Anonymous crash reports, which we collect to help fix bugs within the app
              
Full details about the anonymous data we collect and what we do with it are provided in our Privacy Policy.'''),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      analyticsEnabled = false;
                      widget.db.setAnalyticsEnabled(analyticsEnabled);
                    },
                    child: const Text("No, don't collect anonymous data")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      analyticsEnabled = true;
                      widget.db.setAnalyticsEnabled(analyticsEnabled);
                    },
                    child: const Text("Yes, collect anonymous data"))
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: shortcutMapping,
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewNoteIntent: CallbackAction(
              onInvoke: (Intent intent) =>
                  widget.db.navigateToNote(Note.empty())),
          SearchIntent: CallbackAction(
              onInvoke: (intent) => searchFocusNode.requestFocus())
        },
        child: Scaffold(
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
              widget.db.firebase.analytics.logEvent(name: 'click_new_note_fab');
            },
          ),
          body: Responsive(
            mobile:
                SearchScreenNavigator(db: widget.db, hasInitNote: hasInitNote),
            tablet: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: SearchScreen(
                    key: widget.db.searchKey,
                    db: widget.db,
                    searchFocusNode: searchFocusNode,
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: NoteScreenNavigator(
                      db: widget.db, hasInitNote: hasInitNote),
                ),
              ],
            ),
            desktop: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SearchScreen(
                    key: widget.db.searchKey,
                    db: widget.db,
                    searchFocusNode: searchFocusNode,
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: NoteScreenNavigator(
                      db: widget.db, hasInitNote: hasInitNote),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
