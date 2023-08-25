import 'package:fleeting_notes_flutter/screens/main/components/side_rail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

void onTrash(BuildContext context) {
  context.goNamed('trash');
}

class SideMenu extends StatelessWidget {
  const SideMenu(
      {Key? key,
      this.addNote,
      this.closeDrawer,
      this.width,
      this.searches,
      this.onSearch,
      this.openCreateSearchDialog})
      : super(key: key);

  final VoidCallback? addNote;
  final VoidCallback? closeDrawer;
  final double? width;
  final List<String>? searches;
  final Function(String)? onSearch;
  final VoidCallback? openCreateSearchDialog;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          var text = 'Fleeting Notes';
                          if (snapshot.hasData) {
                            text += ' v${snapshot.data?.version}';
                          }
                          return Text(text,
                              style: Theme.of(context).textTheme.titleMedium);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: closeDrawer,
                      icon: const Icon(Icons.menu_open),
                    )
                  ],
                ),
                const Divider(),
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SAVED SEARCHES',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Column(
                          children: [
                            if (searches != null && searches!.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: searches?.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String? searchQuery = searches?[index];
                                  const int maxTextLength = 15;

                                  String truncatedText = searchQuery ?? "";
                                  if (truncatedText.length > maxTextLength) {
                                    truncatedText = truncatedText.substring(
                                            0, maxTextLength) +
                                        '...';
                                  }

                                  return NavigationButton(
                                    icon: const Icon(Icons.search),
                                    label: Text(
                                      truncatedText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    onTap: () => onSearch!(searchQuery!),
                                  );
                                },
                              ),
                            NavigationButton(
                              icon: const Icon(Icons.edit_outlined),
                              label: Text('Create/Edit searches',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              onTap: () => openCreateSearchDialog!(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 48),
                  child: Divider(),
                ),
                NavigationButton(
                  icon: const Icon(Icons.delete),
                  label: Text('Trash',
                      style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => onTrash(context),
                ),
                NavigationButton(
                  icon: const Icon(Icons.settings),
                  label: Text('Settings',
                      style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => onSetting(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationButton extends StatelessWidget {
  const NavigationButton(
      {super.key, required this.icon, required this.label, this.onTap});
  final Icon icon;
  final Widget label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [icon, const SizedBox(width: 12), Expanded(child: label)],
        ),
      ),
    );
  }
}
