import 'package:fleeting_notes_flutter/screens/main/components/fn_bottom_app_bar.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/one_account_dialog.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/screens/main/components/side_menu.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/search_query.dart';
import '../../widgets/record_dialog.dart';
import 'components/onboarding_dialog.dart';
import 'components/note_fab.dart';
import 'components/side_rail.dart';
import 'components/create_search_dialog.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final scrollController = ScrollController();
  final imagePicker = ImagePicker();
  var searches = <String>[];
  bool bottomAppBarVisible = true;
  FloatingActionButtonLocation get _fabLocation => bottomAppBarVisible
      ? FloatingActionButtonLocation.endContained
      : FloatingActionButtonLocation.endFloat;
  FocusNode searchFocusNode = FocusNode();
  Widget? desktopSideWidget;
  bool bannerExists = false;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    if (!db.loggedIn) {
      db.settings.delete('last-sync-time');
      if (db.settings.isFirstTimeOpen()) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (c) => const OnboardingDialog(width: 300),
          );
        });
      }
    }
    attemptRecoverSession();
    handleSiriSuggestions();
    scrollController.addListener(_listenScroll);
    searches = (db.settings.get("historical-searches") as List? ?? [])
        .map((dynamic item) => item.toString())
        .toList();
  }

  @override
  void dispose() {
    scrollController.removeListener(_listenScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _listenScroll() {
    final ScrollDirection direction =
        scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.forward && !bottomAppBarVisible) {
      setState(() => bottomAppBarVisible = true);
    } else if (direction == ScrollDirection.reverse && bottomAppBarVisible) {
      setState(() => bottomAppBarVisible = false);
    }
  }

  void attemptRecoverSession() async {
    final db = ref.read(dbProvider);
    if (db.loggedIn) return; // dont attempt restore if logged in
    var storedSession = await db.supabase.getStoredSession();
    var session = storedSession?.session;
    if (session != null) {
      if (storedSession?.subscriptionTier == 'free') {
        showDialog(
            context: context,
            builder: (c) => OneAccountDialog(
                  userId: session.user.id,
                  title: "You've been logged out",
                  onContinue: Navigator.of(context).pop,
                  onSeePricing: () {
                    Uri uri =
                        Uri.parse("https://fleetingnotes.app/pricing?ref=app");
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ));
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
    // wait 3 seconds so other activity can be registered
    // https://github.com/myriky/flutter_siri_suggestions/issues/17
    await Future.delayed(const Duration(seconds: 3));
    await FlutterSiriSuggestions.instance.registerActivity(
        const FlutterSiriActivity("Record New Note", "recordActivity",
            isEligibleForSearch: true,
            isEligibleForPrediction: true,
            contentDescription:
                "Launches Fleeting Notes app and opens a dialog to record a new note",
            suggestedInvocationPhrase: "Record fleeting note"));
  }

  void addNote({Note? note, Uint8List? attachment}) {
    final nh = ref.read(noteHistoryProvider.notifier);
    final db = ref.read(dbProvider);
    db.closeDrawer();
    note = note ?? Note.empty();
    nh.addNote(context, note, attachment: attachment);
  }

  void recordNote() async {
    if (kIsWeb ||
        [TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)) {
      await showDialog(
          context: context, builder: (context) => const RecordDialog());
    }
  }

  void onPickImage(ImageSource source) async {
    Navigator.pop(context);
    var img = await imagePicker.pickImage(source: source);
    if (img != null) {
      var bytes = await img.readAsBytes();
      addNote(note: Note.empty(source: img.path), attachment: bytes);
    }
  }

  void onPickImageOption() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PickImageOptions(onPickImage: onPickImage);
      },
    );
  }

  void openCreateSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateSearchDialog(
          addSearch: (search) {
            if (!searches.contains(search)) {
              setState(() {
                searches.add(search);
                updateSearchSettings(searches);
              });
            }
          },
          removeSearch: (index) {
            setState(() {
              searches.removeAt(index);
              updateSearchSettings(searches);
            });
          },
          editSearch: (index, search) {
            setState(() {
              searches[index] = search;
              updateSearchSettings(searches);
            });
          },
          searches: searches,
        );
      },
    );
  }

  void updateSearchSettings(List<String> searches) {
    final db = ref.read(dbProvider);
    const key = "historical-searches";
    db.settings.set(key, searches);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final isMobile = Responsive.isMobile(context);
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
                searches: searches,
                openCreateSearchDialog: () {
                  openCreateSearchDialog(context);
                },
                onSearch: (query) {
                  db.closeDrawer();
                  final searchQuery = ref.read(searchProvider) ?? SearchQuery();
                  final notifier = ref.read(searchProvider.notifier);
                  notifier.updateSearch(searchQuery.copyWith(
                    query: query,
                  ));
                }),
            bottomNavigationBar: FNBottomAppBar(
              isElevated: !bottomAppBarVisible,
              isVisible: isMobile && bottomAppBarVisible,
              onRecord: recordNote,
              onAddChecklist: () {
                addNote(note: Note.empty(content: '- [ ] '));
              },
              onImagePicker: onPickImageOption,
            ),
            floatingActionButtonLocation: _fabLocation,
            floatingActionButton: (isMobile)
                ? NoteFAB(onPressed: addNote, isElevated: !bottomAppBarVisible)
                : null,
            body: SafeArea(
              child: Responsive(
                mobile: SearchScreen(
                    searchFocusNode: searchFocusNode,
                    scrollController: scrollController),
                tablet: Row(
                  children: [
                    SideRail(onMenu: db.openDrawer),
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
                    SideRail(onMenu: db.openDrawer),
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

class PickImageOptions extends StatelessWidget {
  const PickImageOptions({
    super.key,
    required this.onPickImage,
  });

  final Function(ImageSource) onPickImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => onPickImage(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Choose image'),
            onTap: () => onPickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
