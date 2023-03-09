import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/screens/main/components/side_menu.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:flutter/scheduler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'components/analytics_dialog.dart';
import 'components/note_fab.dart';
import 'components/side_rail.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  FocusNode searchFocusNode = FocusNode();
  Widget? desktopSideWidget;
  bool bannerExists = false;
  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    if (!kDebugMode) analyticsDialogWorkflow();
    if (!db.loggedIn && db.settings.isFirstTimeOpen()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('Register / Sign In'),
                content: SizedBox(
                  width: mobileLimit,
                  child: SingleChildScrollView(
                    child: Auth(
                      onLogin: (_) => Navigator.pop(context),
                    ),
                  ),
                )));
      });
    }
  }

  void analyticsDialogWorkflow() {
    final db = ref.read(dbProvider);
    // Privacy Alert Dialog
    if (!kIsWeb) {
      db.setAnalyticsEnabled(true);
      return;
    }
    DeviceInfoPlugin().webBrowserInfo.then((info) {
      if (info.browserName != BrowserName.firefox) {
        db.setAnalyticsEnabled(true);
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) {
        void onAnalyticsPress(analyticsEnabled) {
          Navigator.pop(context);
          db.setAnalyticsEnabled(analyticsEnabled);
        }

        bool? analyticsEnabled = db.settings.get('analytics-enabled');
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

  void addNote() {
    final nh = ref.read(noteHistoryProvider.notifier);
    final db = ref.read(dbProvider);
    db.closeDrawer();
    final note = Note.empty();
    nh.addNote(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Shortcuts(
      shortcuts: shortcutMapping,
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewNoteIntent: CallbackAction(onInvoke: (Intent intent) => addNote()),
          SearchIntent: CallbackAction(
              onInvoke: (intent) => searchFocusNode.requestFocus())
        },
        child: Scaffold(
          key: db.scaffoldKey,
          resizeToAvoidBottomInset: false,
          drawer: SideMenu(
            addNote: addNote,
            closeDrawer: db.closeDrawer,
          ),
          floatingActionButton: (Responsive.isMobile(context))
              ? NoteFAB(onPressed: addNote)
              : null,
          body: Responsive(
            mobile: SearchScreen(searchFocusNode: searchFocusNode),
            tablet: Row(
              children: [
                SideRail(addNote: addNote, onMenu: db.openDrawer),
                Flexible(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: mobileLimit),
                      child: SearchScreen(
                        searchFocusNode: searchFocusNode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            desktop: Row(
              children: [
                SideRail(addNote: addNote, onMenu: db.openDrawer),
                Flexible(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: tabletLimit),
                      child: SearchScreen(
                        searchFocusNode: searchFocusNode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
