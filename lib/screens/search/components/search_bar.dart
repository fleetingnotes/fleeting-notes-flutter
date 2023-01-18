import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_query.dart';
import '../../../utils/responsive.dart';

class SearchBar extends ConsumerStatefulWidget {
  const SearchBar({
    Key? key,
    required this.onMenu,
    this.controller,
    this.focusNode,
  }) : super(key: key);

  final VoidCallback onMenu;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  ConsumerState<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<SearchBar> {
  bool maintainFocus = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode = widget.focusNode ?? focusNode;
    focusNode.addListener(onQueryFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(onQueryFocusChange);
    super.dispose();
  }

  onQueryFocusChange() {
    onQueryChange('');
  }

  onQueryChange(String val) {
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateSearch(searchQuery.copyWith(
      query: val,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchProvider);
    final notifier = ref.watch(searchProvider.notifier);
    bool hasSearchFocus = searchQuery != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: EdgeInsets.symmetric(
        vertical: (hasSearchFocus) ? 0 : 4,
        horizontal: (hasSearchFocus) ? 0 : 16,
      ),
      padding: EdgeInsets.symmetric(vertical: (hasSearchFocus) ? 4 : 0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: (hasSearchFocus)
                    ? BorderRadius.zero
                    : BorderRadius.circular(30)),
            elevation: (hasSearchFocus) ? 0 : 3,
            child: Row(
              children: [
                LeadingIcon(
                  hasFocus: hasSearchFocus,
                  onBack: () => notifier.updateSearch(null),
                  onMenu: widget.onMenu,
                ),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: widget.controller,
                    onChanged: onQueryChange,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Search Notes',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                (hasSearchFocus)
                    ? (Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton(
                          tooltip: "Sort and Filter",
                          padding: const EdgeInsets.all(0),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (_) {
                                return const SearchDialog();
                              },
                            );
                            focusNode.requestFocus();
                          },
                          icon: const Icon(Icons.tune, size: 24),
                        ),
                      ))
                    : (const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.search, size: 24),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeadingIcon extends StatelessWidget {
  const LeadingIcon({
    super.key,
    required this.hasFocus,
    this.onBack,
    this.onMenu,
  });

  final bool hasFocus;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    if (hasFocus) {
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          padding: const EdgeInsets.all(0),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
      );
    } else if (Responsive.isMobile(context)) {
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          tooltip: 'Open Menu',
          padding: const EdgeInsets.all(0),
          onPressed: onMenu,
          icon: const Icon(Icons.menu_outlined, size: 24),
        ),
      );
    } else {
      return const SizedBox(width: 16);
    }
  }
}
