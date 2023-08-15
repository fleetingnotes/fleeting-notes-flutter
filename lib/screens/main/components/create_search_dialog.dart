import 'package:flutter/material.dart';

class CreateSearchDialog extends StatefulWidget {
  final Function(String) addSearch;
  final Function(int) removeSearch;
  final List<String> searches;

  const CreateSearchDialog({
    Key? key,
    required this.addSearch,
    required this.removeSearch,
    required this.searches,
  }) : super(key: key);

  @override
  _CreateSearchDialogState createState() => _CreateSearchDialogState();
}

class _CreateSearchDialogState extends State<CreateSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (stfContext, stfSetState) {
      return AlertDialog(
        title: const Text('Create/Edit Searches'),
        content: SizedBox(
            height: 300,
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration:
                            const InputDecoration(hintText: 'New search'),
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
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.searches.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(widget.searches[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // Implement edit functionality
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
              ],
            )),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      );
    });
  }
}
