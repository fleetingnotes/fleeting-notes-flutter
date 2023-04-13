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
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import '../../widgets/record_dialog.dart';
import 'components/analytics_dialog.dart';
import 'components/onboarding_dialog.dart';
import 'components/note_fab.dart';
import 'components/recover_session_dialog.dart';
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
          builder: (c) => const OnboardingDialog(width: 300),
        );
      });
    }
    attemptRecoverSession();
    handleSiriSuggestions();
  }

  void attemptRecoverSession() async {
    final db = ref.read(dbProvider);
    if (db.loggedIn) return; // dont attempt restore if logged in
    var storedSession = await db.supabase.getStoredSession();
    var session = storedSession?.session;
    if (session != null) {
      if (storedSession?.subscriptionTier == 'free') {
        showDialog(
            context: context, builder: (c) => const RecoverSessionDialog());
      } else {
        db.supabase.recoverSession(session);
      }
    }
  }

  void handleSiriSuggestions() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) return;
    FlutterSiriSuggestions.instance.configure(
        onLaunch: (Map<String, dynamic> message) async {
      debugPrint("called by ${message['key']} suggestion.");
      switch (message['key']) {
        case "createActivity":
          addNote();
          break;
        case "recordActivity":
          recordNote();
          break;
      }
    });
    await FlutterSiriSuggestions.instance.registerActivity(
        const FlutterSiriActivity("Create New Note", "createActivity",
            isEligibleForSearch: true,
            isEligibleForPrediction: true,
            contentDescription:
                "Launches Fleeting Notes app and creates a new note",
            suggestedInvocationPhrase: "Create fleeting note"));
    // TODO: update eligible for search & prediction
    await FlutterSiriSuggestions.instance.registerActivity(
        const FlutterSiriActivity("Record New Note", "recordActivity",
            isEligibleForSearch: true,
            isEligibleForPrediction: true,
            contentDescription:
                "Launches Fleeting Notes app and opens a dialog to record a new note",
            suggestedInvocationPhrase: "Record fleeting note"));
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

  void recordNote() async {
    if (kIsWeb ||
        [TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)) {
      await showDialog(
          context: context, builder: (context) => const RecordDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Shortcuts(
      shortcuts: mainShortcutMapping,
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewNoteIntent: CallbackAction(onInvoke: (Intent intent) => addNote()),
          SearchIntent: CallbackAction(
              onInvoke: (intent) => searchFocusNode.requestFocus())
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            key: db.scaffoldKey,
            resizeToAvoidBottomInset: false,
            drawer: SideMenu(
              addNote: addNote,
              closeDrawer: db.closeDrawer,
            ),
            floatingActionButton: (Responsive.isMobile(context))
                ? NoteFAB(onPressed: addNote, onLongPress: recordNote)
                : null,
            body: SafeArea(
              child: Responsive(
                mobile: SearchScreen(searchFocusNode: searchFocusNode),
                tablet: Row(
                  children: [
                    SideRail(addNote: addNote, onMenu: db.openDrawer),
                    Flexible(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: mobileLimit),
                          child: SearchScreen(
                            searchFocusNode: searchFocusNode,
                            addNote: addNote,
                            recordNote: recordNote,
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
                          constraints:
                              const BoxConstraints(maxWidth: tabletLimit),
                          child: SearchScreen(
                            searchFocusNode: searchFocusNode,
                            addNote: addNote,
                            recordNote: recordNote,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
