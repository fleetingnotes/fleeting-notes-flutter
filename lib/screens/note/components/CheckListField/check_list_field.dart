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
  List<FocusNode> itemFocusNodes = []; // Add this line
  List<TextEditingController> uncheckedItemControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.uncheckedItems.length; i++) {
      itemFocusNodes.add(FocusNode());
      uncheckedItemControllers.add(TextEditingController(
        text: widget.uncheckedItems[i],
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(itemFocusNodes.last);
    });
  }

  @override
  void dispose() {
    for (var focusNode in itemFocusNodes) {
      focusNode.dispose();
    }
    for (var controller in uncheckedItemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addItem() {
    String newItemText = newItemController.text;
    if (newItemText.isNotEmpty) {
      setState(() {
        widget.uncheckedItems.add(newItemText);
        uncheckedItemControllers.add(TextEditingController(
          text: newItemText,
        ));
        itemFocusNodes.add(FocusNode());
        newItemController.clear();
        updateControllerText();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(itemFocusNodes.last);
      });
    }
  }

  void removeUncheckedItem(int index) {
    setState(() {
      widget.uncheckedItems.removeAt(index);
      uncheckedItemControllers.removeAt(index);
      itemFocusNodes.removeAt(index);
      updateControllerText();
    });
  }

  void removeCheckedItem(int index) {
    setState(() {
      widget.checkedItems.removeAt(index);
      updateControllerText();
    });
  }

  void setChecked(int index) {
    setState(() {
      String item = widget.uncheckedItems[index];
      widget.uncheckedItems.removeAt(index);
      uncheckedItemControllers.removeAt(index);
      widget.checkedItems.add(item);
      updateControllerText();
    });
  }

  void setUnChecked(int index) {
    setState(() {
      String item = widget.checkedItems[index];
      widget.checkedItems.removeAt(index);
      widget.uncheckedItems.add(item);
      uncheckedItemControllers.add(TextEditingController(
        text: item,
      ));
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
    widget.controller.text = generateListText();
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
                        hintText: 'List item',
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
                onPressed: () => removeUncheckedItem(index),
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (_) => setChecked(index),
                  ),
                  Expanded(
                    child: TextField(
                      controller: uncheckedItemControllers[index],
                      onChanged: (newText) {
                        widget.uncheckedItems[index] = newText;
                        updateControllerText();
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      focusNode: itemFocusNodes[index],
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
                        onPressed: () => removeCheckedItem(index),
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
