import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchDialog extends ConsumerWidget {
  final VoidCallback? onClose;

  const SearchDialog({
    Key? key,
    this.onClose,
  }) : super(key: key);

  updateSearchFilter(WidgetRef ref, String key, bool val) {
    final searchQuery = ref.read(searchProvider) ?? SearchQuery();
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateSearch(searchQuery.copyWith(
      searchByTitle: (key == 'title') ? val : null,
      searchByContent: (key == 'content') ? val : null,
      searchBySource: (key == 'source') ? val : null,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchProvider) ?? SearchQuery();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close))
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 36),
                child: Text('Sort By',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const Expanded(child: DropdownSortMenu()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 36),
                child: Text('Filter By',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text('Title',
                          style: Theme.of(context).textTheme.labelLarge),
                      selected: searchQuery.searchByTitle,
                      onSelected: (val) =>
                          updateSearchFilter(ref, 'title', val),
                    ),
                    FilterChip(
                      label: Text('Content',
                          style: Theme.of(context).textTheme.labelLarge),
                      selected: searchQuery.searchByContent,
                      onSelected: (val) =>
                          updateSearchFilter(ref, 'content', val),
                    ),
                    FilterChip(
                      label: Text('Source',
                          style: Theme.of(context).textTheme.labelLarge),
                      selected: searchQuery.searchBySource,
                      onSelected: (val) =>
                          updateSearchFilter(ref, 'source', val),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DropdownSortMenu extends ConsumerStatefulWidget {
  const DropdownSortMenu({
    Key? key,
  }) : super(key: key);

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
    final sq = ref.read(searchProvider) ?? SearchQuery();
    var sortByStr = sq.sortBy.toString().split('.').last.toLowerCase();
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
    final sq = ref.read(searchProvider) ?? SearchQuery();
    final notifier = ref.read(searchProvider.notifier);
    var sortOption = sortOptionMap["$sortVal-$sortDir"];
    notifier.updateSearch(sq.copyWith(sortBy: sortOption));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(width: 16),
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
