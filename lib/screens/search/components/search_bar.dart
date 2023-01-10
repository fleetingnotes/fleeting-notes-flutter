import 'package:fleeting_notes_flutter/screens/search/components/search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchBar extends ConsumerStatefulWidget {
  const SearchBar({
    Key? key,
    required this.onMenuPressed,
    this.onTap,
    this.onChanged,
    this.controller,
    this.focusNode,
  }) : super(key: key);

  final VoidCallback onMenuPressed;
  final VoidCallback? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  ConsumerState<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<SearchBar> {
  bool hasFocus = false;
  bool maintainFocus = false;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode = widget.focusNode ?? focusNode;
    focusNode.addListener(onSearchFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.removeListener(onSearchFocusChange);
  }

  onSearchFocusChange() {
    bool nodeHasFocus = focusNode.hasFocus;
    if (nodeHasFocus) {
      setState(() {
        hasFocus = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: EdgeInsets.symmetric(
        vertical: (hasFocus) ? 0 : 8,
        horizontal: (!hasFocus) ? 16 : 0,
      ),
      padding: EdgeInsets.symmetric(vertical: (hasFocus) ? 8 : 0),
      decoration: BoxDecoration(
        borderRadius: (hasFocus) ? null : BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Row(
        children: [
          (hasFocus)
              ? (Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      focusNode.unfocus();
                      setState(() {
                        hasFocus = false;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                ))
              : (Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: widget.onMenuPressed,
                    icon: const Icon(Icons.menu_outlined, size: 24),
                  ),
                )),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: widget.controller,
              onChanged: (val) => widget.onChanged?.call(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          (hasFocus)
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
    );
  }
}
