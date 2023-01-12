import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/screens/main/components/side_menu.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:fleeting_notes_flutter/screens/note/note_screen_navigator.dart';
import 'package:flutter/scheduler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'components/analytics_dialog.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key, this.initNote}) : super(key: key);

  final Note? initNote;
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  FocusNode searchFocusNode = FocusNode();
  late bool hasInitNote;
  bool bannerExists = false;
  @override
  void initState() {
    super.initState();
    var note = widget.initNote;
    final db = ref.read(dbProvider);
    if (note == null) {
      hasInitNote = false;
    } else {
      hasInitNote = true;
    }
    var isSharedNotes = db.isSharedNotes;
    if (!kDebugMode) analyticsDialogWorkflow();
    if (!db.isLoggedIn() && !isSharedNotes && db.settings.isFirstTimeOpen()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('Register / Sign In'),
                content: Auth(
                  onLogin: (_) async {
                    await db.getAllNotes(forceSync: true);
                    Navigator.pop(context);
                    // wait to make sure the user is logged in
                    Future.delayed(const Duration(milliseconds: 500), () {
                      setState(() {
                        db.refreshApp();
                      });
                    });
                  },
                )));
      });
    }
    if (isSharedNotes && !bannerExists) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        MaterialBanner sharedNotesBanner = MaterialBanner(
          content:
              const Text('These are shared notes, edits will not be saved'),
          actions: [
            Builder(builder: (context) {
              return TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).removeCurrentMaterialBanner();
                  setState(() {
                    hasInitNote = false;
                    bannerExists = false;
                    db.refreshApp();
                  });
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final noteUtils = ref.watch(noteUtilsProvider);
    return WillPopScope(
      onWillPop: () async {
        return !db.canPop();
      },
      child: Shortcuts(
        shortcuts: shortcutMapping,
        child: Actions(
          actions: <Type, Action<Intent>>{
            NewNoteIntent: CallbackAction(
                onInvoke: (Intent intent) => db.navigateToNote(Note.empty())),
            SearchIntent: CallbackAction(
                onInvoke: (intent) => searchFocusNode.requestFocus())
          },
          child: Scaffold(
            key: db.scaffoldKey,
            resizeToAvoidBottomInset: false,
            drawer: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: const SideMenu(),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              child: const Icon(Icons.add),
              tooltip: 'Add note',
              onPressed: () {
                noteUtils.openNoteEditorDialog(context, Note.empty());
              },
            ),
            body: Responsive(
              mobile: SearchScreenNavigator(hasInitNote: hasInitNote),
              tablet: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: SearchScreen(
                      key: db.searchKey,
                      searchFocusNode: searchFocusNode,
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: NoteScreenNavigator(hasInitNote: hasInitNote),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchScreen(
                      key: db.searchKey,
                      searchFocusNode: searchFocusNode,
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: NoteScreenNavigator(hasInitNote: hasInitNote),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
