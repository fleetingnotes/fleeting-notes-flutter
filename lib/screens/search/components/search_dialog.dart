import 'package:flutter/material.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({
    Key? key,
    required this.searchFilter,
    required this.onFilterChange,
  }) : super(key: key);

  final Map searchFilter;
  final Function onFilterChange;

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late Map searchFilter;

  @override
  void initState() {
    super.initState();
    searchFilter = widget.searchFilter;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Search By:'),
      children: [
        CheckboxListTile(
          title: const Text('Title'),
          value: searchFilter['title'],
          onChanged: (newValue) {
            setState(() {
              searchFilter['title'] = newValue;
            });
            widget.onFilterChange('title', newValue);
          },
        ),
        CheckboxListTile(
          title: const Text('Content'),
          value: searchFilter['content'],
          onChanged: (newValue) {
            setState(() {
              searchFilter['content'] = newValue;
            });
            widget.onFilterChange('content', newValue);
          },
        ),
        CheckboxListTile(
          title: const Text('Source'),
          value: searchFilter['source'],
          onChanged: (newValue) {
            setState(() {
              searchFilter['source'] = newValue;
            });
            widget.onFilterChange('source', newValue);
          },
        ),
      ],
    );
  }
}
