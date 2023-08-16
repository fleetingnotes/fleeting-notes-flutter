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
  bool isEditing = false;
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
                  String editedText = widget.searches[index];
                  return ListTile(
                    title: isEditing && editingIndex == index
                        ? TextFormField(
                            initialValue: widget.searches[index],
                            onChanged: (value) {
                              editedText = value;
                            },
                            onFieldSubmitted: (value) {
                              widget.editSearch(index, editedText);
                              setState(() {
                                isEditing = false;
                                editingIndex = -1;
                              });
                            },
                          )
                        : Text(widget.searches[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: isEditing && editingIndex == index
                              ? const Icon(Icons.check)
                              : const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              if (isEditing && editingIndex == index) {
                                widget.editSearch(index, editedText);
                                isEditing = false;
                                editingIndex = -1;
                              } else {
                                isEditing = true;
                                editingIndex = index;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.removeSearch(index);
                            stfSetState(() {});
                          },
                        ),
                      ],
                    ),
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
