import 'package:fleeting_notes_flutter/screens/note/note_list.dart';
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
  const MainScreen({Key? key, this.initNote}) : super(key: key);

  final Note? initNote;
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
    Note? initNote = widget.initNote;
    final db = ref.read(dbProvider);
    var isSharedNotes = db.isSharedNotes;
    var newNoteOnOpen =
        db.settings.get('new-note-on-open', defaultValue: false);
    if (initNote != null || newNoteOnOpen) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        final noteUtils = ref.read(noteUtilsProvider);
        var dialogNote = initNote;
        dialogNote ??= Note.empty();
        noteUtils.openNoteEditorDialog(context, dialogNote);
      });
    }
    if (!kDebugMode) analyticsDialogWorkflow();
    if (!db.isLoggedIn() && !isSharedNotes && db.settings.isFirstTimeOpen()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                title: const Text('Register / Sign In'),
                content: SizedBox(
                  width: 599,
                  child: Auth(
                    onLogin: (_) async {
                      await db.getAllNotes(forceSync: true);
                      Navigator.pop(context);
                      // wait to make sure the user is logged in
                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() {
                          db.refreshApp(ref);
                        });
                      });
                    },
                  ),
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
                    bannerExists = false;
                    db.refreshApp(ref);
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

  void addNote() {
    final noteUtils = ref.read(noteUtilsProvider);
    final db = ref.read(dbProvider);
    final search = ref.read(searchProvider.notifier);
    db.closeDrawer();
    search.updateSearch(null);
    noteUtils.openNoteEditorDialog(context, Note.empty());
  }

  void toggleDrawerDesktop() {
    setState(() {
      if (desktopSideWidget == null) {
        desktopSideWidget = SideMenu(
            addNote: addNote, closeDrawer: toggleDrawerDesktop, width: 240);
      } else {
        desktopSideWidget = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final searchQuery = ref.watch(searchProvider);
    final viewedNotes = ref.watch(viewedNotesProvider);
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
          drawer: (Responsive.isDesktop(context))
              ? null
              : SideMenu(
                  addNote: addNote,
                  closeDrawer: db.closeDrawer,
                ),
          floatingActionButton: (Responsive.isMobile(context))
              ? NoteFAB(onPressed: addNote)
              : null,
          body: SafeArea(
            child: Responsive(
              mobile: SearchScreen(
                searchFocusNode: searchFocusNode,
                child: (searchQuery != null || viewedNotes.isEmpty)
                    ? null
                    : const NoteList(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                      ),
              ),
              tablet: Row(
                children: [
                  SideRail(addNote: addNote, onMenu: db.openDrawer),
                  Expanded(
                    flex: 6,
                    child: SearchScreen(
                      searchFocusNode: searchFocusNode,
                    ),
                  ),
                  const Expanded(
                    flex: 9,
                    child: NoteList(
                      padding: EdgeInsets.only(top: 4, right: 8),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Stack(
                    children: [
                      if (desktopSideWidget == null)
                        SideRail(addNote: addNote, onMenu: toggleDrawerDesktop),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (widget, animation) {
                          const begin = Offset(-1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          final offsetAnimation = animation.drive(tween);
                          return SlideTransition(
                            position: offsetAnimation,
                            child: widget,
                          );
                        },
                        child: desktopSideWidget,
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 360,
                    child: SearchScreen(
                      searchFocusNode: searchFocusNode,
                    ),
                  ),
                  const Expanded(
                    flex: 9,
                    child: NoteList(
                      padding: EdgeInsets.only(top: 4, right: 8),
                    ),
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
