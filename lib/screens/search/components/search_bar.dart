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
  bool hasSearchFocus = false;
  MenuController menuController = MenuController();
  FocusNode focusNode = FocusNode();
  FocusNode menuFocusNode = FocusNode();

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
    final searchQuery = ref.read(searchProvider);
    if (focusNode.hasFocus) {
      setState(() {
        hasSearchFocus = true;
      });
    }
    if (searchQuery == null && focusNode.hasFocus) {
      onQueryChange('');
    }
  }

  onQueryChange(String val) {
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateSearch(searchQuery.copyWith(
      query: val,
    ));
  }

  onBack() {
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateSearch(null);
    setState(() {
      focusNode.unfocus();
      hasSearchFocus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool searchFocusMobile = hasSearchFocus && Responsive.isMobile(context);
    return AnimatedContainer(
      height: 72,
      duration: const Duration(milliseconds: 100),
      child: Card(
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: (searchFocusMobile)
                ? BorderRadius.zero
                : BorderRadius.circular(30)),
        elevation: (searchFocusMobile) ? 0 : 3,
        child: Row(
          children: [
            LeadingIcon(
              hasFocus: searchFocusMobile,
              onBack: onBack,
              onMenu: widget.onMenu,
            ),
            Expanded(
              child: TextField(
                focusNode: focusNode,
                onTap: () {
                  setState(() {
                    hasSearchFocus = true;
                  });
                },
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
            (searchFocusMobile || !Responsive.isMobile(context))
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: MenuAnchor(
                      childFocusNode: menuFocusNode,
                      style: const MenuStyle(
                        padding: MaterialStatePropertyAll(EdgeInsets.zero),
                      ),
                      controller: menuController,
                      menuChildren: [
                        SearchDialog(onClose: menuController.close),
                      ],
                      child: IconButton(
                        padding: const EdgeInsets.all(0),
                        tooltip: "Sort and Filter",
                        onPressed: menuController.open,
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: (Icon(Icons.search)),
                  ),
          ],
        ),
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
      return const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.search, size: 24),
      );
    }
  }
}
