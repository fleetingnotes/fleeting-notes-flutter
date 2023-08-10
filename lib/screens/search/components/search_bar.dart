import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_query.dart';
import '../../../utils/responsive.dart';

class CustomSearchBar extends ConsumerStatefulWidget {
  const CustomSearchBar(
      {super.key, required this.onMenu, this.controller, this.focusNode});
  final VoidCallback onMenu;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  ConsumerState<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends ConsumerState<CustomSearchBar> {
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
    final db = ref.read(dbProvider);
    TextDirection textDirection =
    db.settings.get('right-to-left', defaultValue: false)
            ? TextDirection.rtl
            : TextDirection.ltr;
    bool searchFocusMobile = hasSearchFocus && Responsive.isMobile(context);
    
    return Directionality(
      textDirection: textDirection,
      child: SearchBar(
          leading: LeadingIcon(
            hasFocus: searchFocusMobile,
            onBack: onBack,
            onMenu: widget.onMenu,
          ),
          hintText: "Search Notes",
          focusNode: focusNode,
          onTap: () {
            setState(() {
              hasSearchFocus = true;
            });
          },
          onChanged: onQueryChange,
          trailing: [
            (searchFocusMobile || !Responsive.isMobile(context))
                ? MenuAnchor(
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
                  )
                : const Padding(
                  padding: EdgeInsets.only(right:16.0),
                  child: (Icon(Icons.search)),
                ),
          ]),
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
      return IconButton(
        padding: const EdgeInsets.all(0),
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, size: 24),
      );
    } else if (Responsive.isMobile(context)) {
      return IconButton(
        tooltip: 'Open Menu',
        padding: const EdgeInsets.all(0),
        onPressed: onMenu,
        icon: const Icon(Icons.menu_outlined, size: 24),
      );
    } else {
      return const Icon(Icons.search, size: 24);
    }
  }
}
