import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/utils/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final scrollController = ScrollController();
  final imagePicker = ImagePicker();
  FocusNode searchFocusNode = FocusNode();
  Widget? desktopSideWidget;
  bool bannerExists = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final banner = MaterialBanner(
      content: Text(
        "Deleted Notes",
        style: Theme.of(context).textTheme.titleMedium,
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.goNamed('home');
          },
          child: const Text('Go Back'),
        ),
      ],
    );

    final searchScreen = SearchScreen(
        searchFocusNode: searchFocusNode,
        scrollController: scrollController,
        deletedNotesMode: true);

    final responsiveSearchScreen = Responsive(
      mobile: searchScreen,
      tablet: Row(children: [Flexible(child: searchScreen)]),
      desktop: Row(children: [Flexible(child: searchScreen)]),
    );
    return Shortcuts(
      shortcuts: mainShortcutMapping,
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction(
              onInvoke: (intent) => searchFocusNode.requestFocus())
        },
        child: FocusScope(
            autofocus: true,
            child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: SafeArea(
                    child: Column(
                  children: [
                    banner,
                    Expanded(child: responsiveSearchScreen),
                  ],
                )))),
      ),
    );
  }
}

class MaterialBannerExample extends StatelessWidget {
  const MaterialBannerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The MaterialBanner is below'),
      ),
      body: const MaterialBanner(
        padding: EdgeInsets.all(20),
        content: Text('Hello, I am a Material Banner'),
        leading: Icon(Icons.agriculture_outlined),
        backgroundColor: Color(0xFFE0E0E0),
        actions: <Widget>[
          TextButton(
            onPressed: null,
            child: Text('OPEN'),
          ),
          TextButton(
            onPressed: null,
            child: Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}
