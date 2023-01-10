import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({
    Key? key,
    this.onChange,
  }) : super(key: key);

  final VoidCallback? onChange;

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog> {
  updateSearchFilter(String key, bool val) {
    final searchQuery = ref.read(searchProvider);
    setState(() {
      if (key == 'title') {
        searchQuery.searchByTitle = val;
      } else if (key == 'content') {
        searchQuery.searchByContent = val;
      } else if (key == 'source') {
        searchQuery.searchBySource = val;
      }
    });
    widget.onChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchProvider);
    return SimpleDialog(
      title: const Text('Sort and Filter'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort By', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownSortMenu(onChange: widget.onChange),
              const SizedBox(height: 24),
              Text('Filter By', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Title',
                        style: Theme.of(context).textTheme.labelLarge),
                    selected: searchQuery.searchByTitle,
                    onSelected: (val) => updateSearchFilter('title', val),
                  ),
                  FilterChip(
                    label: Text('Content',
                        style: Theme.of(context).textTheme.labelLarge),
                    selected: searchQuery.searchByContent,
                    onSelected: (val) => updateSearchFilter('content', val),
                  ),
                  FilterChip(
                    label: Text('Source',
                        style: Theme.of(context).textTheme.labelLarge),
                    selected: searchQuery.searchBySource,
                    onSelected: (val) => updateSearchFilter('source', val),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}

class DropdownSortMenu extends ConsumerStatefulWidget {
  const DropdownSortMenu({
    Key? key,
    this.onChange,
  }) : super(key: key);

  final VoidCallback? onChange;

  @override
  ConsumerState<DropdownSortMenu> createState() => _DropdownSortMenuState();
}

class _DropdownSortMenuState extends ConsumerState<DropdownSortMenu> {
  String sortVal = 'created';
  String sortDir = 'desc';
  SortOptions sortOption = SortOptions.createdDESC;

  @override
  void initState() {
    super.initState();
    final searchQuery = ref.read(searchProvider);
    var sortByStr = searchQuery.sortBy.toString().split('.').last.toLowerCase();
    setState(() {
      sortDir = sortByStr.endsWith('asc') ? 'asc' : 'desc';
      sortVal = sortByStr.replaceFirst(sortDir, '');
    });
  }

  void setSortDir(bool isAscending) {
    setState(() {
      sortDir = (isAscending) ? 'asc' : 'desc';
    });
    saveSortState();
  }

  void setSortVal(String? newSortVal) {
    if (newSortVal == null) return;
    setState(() {
      sortVal = newSortVal;
    });
    saveSortState();
  }

  void saveSortState() {
    final searchQuery = ref.read(searchProvider);
    var sortOption = sortOptionMap["$sortVal-$sortDir"];
    if (sortOption != null) {
      searchQuery.sortBy = sortOption;
    }
    widget.onChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownMenu(
          onSelected: setSortVal,
          initialSelection: sortVal,
          enableSearch: false,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'modified', label: 'Modified At'),
            DropdownMenuEntry(value: 'created', label: 'Created At'),
            DropdownMenuEntry(value: 'title', label: 'Title'),
            DropdownMenuEntry(value: 'content', label: 'Content'),
            DropdownMenuEntry(value: 'source', label: 'Source'),
          ],
        ),
        const Spacer(),
        (sortDir == 'asc')
            ? (IconButton(
                onPressed: () => setSortDir(false),
                icon: const Icon(Icons.arrow_upward),
                tooltip: "Ascending",
              ))
            : (IconButton(
                onPressed: () => setSortDir(true),
                icon: const Icon(Icons.arrow_downward),
                tooltip: "Descending",
              ))
      ],
    );
  }
}
