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
  void onAddSearch() {
    final searchTerm = _searchController.text;
    if (searchTerm.isNotEmpty) {
      widget.addSearch(searchTerm);
      _searchController.clear();
      setState(() {});
    }
  }

  void setEditingIndex(int index) {
    setState(() {
      editingIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicDialog(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Edit searches',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
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
                      onSubmitted: (_) => onAddSearch(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: onAddSearch,
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
                    onEdition: () => setEditingIndex(index),
                    isEditing: index == editingIndex,
                    onNotEdition: () => setEditingIndex(-1),
                    editSearch: (String newSearch) {
                      widget.editSearch(index, newSearch);
                      setEditingIndex(-1);
                    },
                    removeSearch: () {
                      widget.removeSearch(index);
                      setEditingIndex(-1);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
  FocusNode textfieldFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) textfieldFocus.requestFocus();
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
        child: Container(
          decoration: (widget.isEditing)
              ? BoxDecoration(
                  border: Border.all(
                  width: 1,
                  color: Theme.of(context).colorScheme.onBackground,
                ))
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: isHovered || widget.isEditing
                    ? const Icon(Icons.delete)
                    : const Icon(Icons.search),
                onPressed: () {
                  if (isHovered || widget.isEditing) widget.removeSearch();
                },
              ),
              if (widget.isEditing)
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(border: InputBorder.none),
                    focusNode: textfieldFocus,
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
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              else
                Expanded(
                    child: Text(widget.search,
                        style: const TextStyle(fontSize: 14))),
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
