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
    required this.onBack,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hasSearchFocus = false,
  }) : super(key: key);

  final VoidCallback onMenu;
  final VoidCallback onBack;
  final VoidCallback? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasSearchFocus;

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
  }

  onQueryChange(String val) {
    var searchNotifier = ref.read(searchProvider.notifier);
    searchNotifier.updateSearch(SearchQuery(
      query: val,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: EdgeInsets.symmetric(
        vertical: (widget.hasSearchFocus) ? 0 : 4,
        horizontal: (widget.hasSearchFocus) ? 0 : 16,
      ),
      padding: EdgeInsets.symmetric(vertical: (widget.hasSearchFocus) ? 4 : 0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: (widget.hasSearchFocus)
                    ? BorderRadius.zero
                    : BorderRadius.circular(30)),
            elevation: (widget.hasSearchFocus) ? 0 : 3,
            child: Row(
              children: [
                LeadingIcon(
                  hasFocus: widget.hasSearchFocus,
                  onBack: widget.onBack,
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
                (widget.hasSearchFocus)
                    ? (Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton(
                          tooltip: "Sort and Filter",
                          padding: const EdgeInsets.all(0),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (_) {
                                return SearchDialog(
                                  onChange: widget.onChanged?.call,
                                );
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
