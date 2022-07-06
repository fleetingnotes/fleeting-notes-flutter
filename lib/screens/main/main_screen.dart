import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/widgets/side_menu.dart';
import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen_navigator.dart';
import 'package:flutter/scheduler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'components/analytics_dialog.dart';

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
  bool bannerExists = false;
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
    if (!kDebugMode) analyticsDialogWorkflow();
    if (widget.db.isFirstTimeOpen() && !widget.db.isLoggedIn()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('Register / Sign In'),
                content: Auth(
                  db: widget.db,
                  onLogin: (_) async {
                    await widget.db.getAllNotes(forceSync: true);
                    Navigator.pop(context);
                    // wait to make sure the user is logged in
                    Future.delayed(const Duration(milliseconds: 500), () {
                      setState(() {
                        widget.db.refreshApp();
                      });
                    });
                  },
                )));
      });
    }
    if (widget.db.firebase.isSharedNotes && !bannerExists) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        MaterialBanner sharedNotesBanner = MaterialBanner(
          content:
              const Text('These are shared notes, edits will not be saved'),
          actions: [
            Builder(builder: (context) {
              return TextButton(
                onPressed: () {
                  widget.db.firebase.analytics
                      .logEvent(name: 'shared_notes_banner_clicked');
                  ScaffoldMessenger.of(context).removeCurrentMaterialBanner();
                  bannerExists = false;
                  widget.db.refreshApp();
                  context.go('/');
                },
                child: const Text('Your Notes'),
              );
            })
          ],
        );
        ScaffoldMessenger.of(context).showMaterialBanner(sharedNotesBanner);
        bannerExists = true;
      });
    }
  }

  void analyticsDialogWorkflow() {
    // Privacy Alert Dialog
    if (!kIsWeb) {
      widget.db.setAnalyticsEnabled(true);
      return;
    }
    DeviceInfoPlugin().webBrowserInfo.then((info) {
      if (info.browserName != BrowserName.firefox) {
        widget.db.setAnalyticsEnabled(true);
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        void onAnalyticsPress(analyticsEnabled) {
          Navigator.pop(context);
          widget.db.setAnalyticsEnabled(analyticsEnabled);
        }

        bool? analyticsEnabled = widget.db.getAnalyticsEnabled();
        if (analyticsEnabled == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AnalyticsDialog(onAnalyticsPress: onAnalyticsPress);
            },
          );
        }
      });
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
