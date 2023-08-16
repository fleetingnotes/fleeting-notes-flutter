import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';

class CreateSearchDialog extends StatefulWidget {
  final Function(String) addSearch;
  final Function(int) removeSearch;
  final Function(int, String) editSearch;
  final List<String> searches;

  const CreateSearchDialog({
    Key? key,
    required this.addSearch,
    required this.removeSearch,
    required this.searches,
    required this.editSearch,
  }) : super(key: key);

  @override
  _CreateSearchDialogState createState() => _CreateSearchDialogState();
}

class _CreateSearchDialogState extends State<CreateSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  int editingIndex = -1;
  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (stfContext, stfSetState) {
      return DynamicDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit searches',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration:
                          const InputDecoration(hintText: 'Create new search'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final searchTerm = _searchController.text;
                      if (searchTerm.isNotEmpty) {
                        widget.addSearch(searchTerm);
                        _searchController.clear();
                        stfSetState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.searches.length,
                itemBuilder: (context, index) {
                  return SearchItem(
                    search: widget.searches[index],
                    onEdition: () {
                      setState(() {
                        editingIndex = index;
                      });
                    },
                    isEditing: index == editingIndex,
                    onNotEdition: () {
                      setState(() {
                        editingIndex = -1;
                      });
                    },
                    editSearch: (String newSearch) {
                      widget.editSearch(index, newSearch);
                      setState(() {
                        editingIndex = -1;
                      });
                      stfSetState(() {});
                    },
                    removeSearch: () {
                      widget.removeSearch(index);
                      stfSetState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class SearchItem extends StatefulWidget {
  final String search;
  final Function(String) editSearch;
  final Function removeSearch;
  final Function onEdition;
  final bool isEditing;
  final Function onNotEdition;

  const SearchItem(
      {super.key,
      required this.search,
      required this.editSearch,
      required this.removeSearch,
      required this.onEdition,
      required this.isEditing,
      required this.onNotEdition});

  @override
  _SearchItemState createState() => _SearchItemState();
}

class _SearchItemState extends State<SearchItem> {
  String editedText = '';
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            widget.onEdition();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: isHovered || widget.isEditing
                    ? const Icon(Icons.delete)
                    : const Icon(Icons.search),
                onPressed: () {
                  widget.removeSearch();
                },
              ),
              if (widget.isEditing)
                Expanded(
                  child: TextFormField(
                    initialValue: widget.search,
                    onChanged: (value) {
                      setState(() {
                        editedText = value; // Update the local editedText state
                      });
                    },
                    onFieldSubmitted: (value) {
                      widget.editSearch(editedText);
                      widget.onEdition();
                    },
                  ),
                )
              else
                Expanded(child: Text(widget.search)),
              IconButton(
                icon: widget.isEditing
                    ? const Icon(Icons.check)
                    : const Icon(Icons.edit),
                onPressed: () {
                  if (!widget.isEditing) {
                    widget.onEdition();
                    setState(() {
                      editedText = widget.search;
                    });
                  } else {
                    widget.editSearch(editedText);
                    widget.onNotEdition();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
