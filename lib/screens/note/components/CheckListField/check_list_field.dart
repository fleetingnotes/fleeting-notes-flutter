import 'package:flutter/material.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({
    Key? key,
    required this.checkedItems,
    required this.uncheckedItems,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  final List<String> checkedItems;
  final List<String> uncheckedItems;
  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool _showCompletedItems = true;

  TextEditingController newItemController = TextEditingController();

  void addItem() {
    String newItemText = newItemController.text;
    if (newItemText.isNotEmpty) {
      setState(() {
        widget.uncheckedItems.add(newItemText);
        newItemController.clear();
        updateControllerText();
      });
    }
  }

  void removeItem(int index) {
    setState(() {
      widget.checkedItems.removeAt(index);
      widget.uncheckedItems.removeAt(index);
    });
  }

  void setChecked(int index) {
    setState(() {
      String item = widget.uncheckedItems[index];
      widget.uncheckedItems.removeAt(index);
      widget.checkedItems.add(item);
      updateControllerText();
    });
  }

  void setUnChecked(int index) {
    setState(() {
      String item = widget.checkedItems[index];
      widget.checkedItems.removeAt(index);
      widget.uncheckedItems.add(item);
      updateControllerText();
    });
  }

  String generateListText() {
    final lines = <String>[];
    for (int i = 0; i < widget.uncheckedItems.length; i++) {
      lines.add('- [ ] ${widget.uncheckedItems[i]}');
    }
    for (int i = 0; i < widget.checkedItems.length; i++) {
      lines.add('- [x] ${widget.checkedItems[i]}');
    }
    return lines.join('\n');
  }

  void updateControllerText() {
    setState(() {
      widget.controller.text = generateListText();
    });
    widget.onChanged!();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: widget.uncheckedItems.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.uncheckedItems.length) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addItem,
                  ),
                  Expanded(
                    child: TextField(
                      controller: newItemController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          addItem();
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Element from the list',
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => removeItem(index),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: widget.checkedItems.contains(
                      widget.uncheckedItems[index],
                    ),
                    onChanged: (_) => setChecked(index),
                  ),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: widget.uncheckedItems[index],
                      ),
                      onChanged: (newText) {
                        setState(() {
                          widget.uncheckedItems[index] = newText;
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      focusNode: FocusNode(skipTraversal: true),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.checkedItems.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              InkWell(
                onTap: () {
                  setState(() {
                    _showCompletedItems = !_showCompletedItems;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showCompletedItems
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                    ),
                    Text('${widget.checkedItems.length} items completed'),
                  ],
                ),
              ),
              if (_showCompletedItems)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.checkedItems.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final String item = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => removeItem(index),
                      ),
                      title: Row(
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (_) => setUnChecked(index),
                          ),
                          Text(
                            item,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
      ],
    );
  }
}
