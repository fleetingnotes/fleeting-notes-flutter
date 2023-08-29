import 'package:flutter/material.dart';

class ChecklistField extends StatefulWidget {
  const ChecklistField(
      {Key? key,
      required this.checkedItems,
      required this.uncheckedItems,
      required this.controller,
      this.onChanged})
      : super(key: key);

  final List<String> checkedItems;
  final List<String> uncheckedItems;
  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  _ChecklistFieldState createState() => _ChecklistFieldState();
}

class _ChecklistFieldState extends State<ChecklistField> {
  bool _showCompletedItems = true;

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
    if (itemFocusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(itemFocusNodes.last);
      });
    }
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
    String newItemText = "";
    setState(() {
      widget.uncheckedItems.add(newItemText);
      uncheckedItemControllers.add(TextEditingController(
        text: newItemText,
      ));
      itemFocusNodes.add(FocusNode());
      updateControllerText();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(itemFocusNodes.last);
    });
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
      itemFocusNodes.add(FocusNode());
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
                    child: GestureDetector(
                      onTap: addItem,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text(
                          'List item',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
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
                        if (newText.isEmpty) {
                          removeUncheckedItem(index);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            FocusScope.of(context)
                                .requestFocus(itemFocusNodes.last);
                          });
                          return;
                        }
                        widget.uncheckedItems[index] = newText;
                        updateControllerText();
                      },
                      focusNode: itemFocusNodes[index],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (newItem) {
                        addItem();
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 1,
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
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => removeCheckedItem(index),
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: true,
                            onChanged: (_) => setUnChecked(index),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          )
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
