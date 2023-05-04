import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Toolbar that provides document editing capabilities, like converting
/// paragraphs to blockquotes and list items, and inserting horizontal
/// rules.
///
/// This toolbar is intended to be placed just above the keyboard on a
/// mobile device.
class ContentEditingToolbar extends StatelessWidget {
  const ContentEditingToolbar({
    Key? key,
    required this.document,
    required this.composer,
    required this.commonOps,
    this.brightness,
  }) : super(key: key);

  final Document document;
  final DocumentComposer composer;
  final CommonEditorOperations commonOps;
  final Brightness? brightness;

  void _addTag() => _addSurroundingText(start: '#', end: '');
  void _addWikiLinks() {
    final selection = composer.selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      _addSurroundingText(start: '[[', end: '');
    } else {
      _addSurroundingText(start: '[[', end: ']]');
    }
  }

  bool get _isBoldActive => _doesSelectionHaveAttributions({boldAttribution});
  void _toggleBold() => _toggleAttributions({boldAttribution});

  bool get _isItalicsActive =>
      _doesSelectionHaveAttributions({italicsAttribution});
  void _toggleItalics() => _toggleAttributions({italicsAttribution});

  bool _doesSelectionHaveAttributions(Set<Attribution> attributions) {
    final selection = composer.selection;
    if (selection == null) {
      return false;
    }

    if (selection.isCollapsed) {
      return composer.preferences.currentAttributions.containsAll(attributions);
    }

    return document.doesSelectedTextContainAttributions(
        selection, attributions);
  }

  void _addSurroundingText({String start = '', String end = ''}) {
    final selection = composer.selection;
    if (selection == null) return;
    if (selection.base.nodeId != selection.extent.nodeId) return;
    final selectedNode = document.getNodeById(selection.extent.nodeId);
    if (selectedNode == null) return;

    var nodeSelection = selectedNode.computeSelection(
        base: selection.base.nodePosition,
        extent: selection.extent.nodePosition) as TextNodeSelection;
    String selectedContent = selectedNode.copyContent(nodeSelection) ?? '';
    commonOps.insertPlainText(start + selectedContent + end);

    var newSelelectionBase = selection.base.copyWith(
        nodePosition:
            TextNodePosition(offset: nodeSelection.baseOffset + start.length));
    var newSelelectionExtent = selection.base.copyWith(
        nodePosition: TextNodePosition(
            offset: nodeSelection.extentOffset + start.length));
    commonOps.selectRegion(
        baseDocumentPosition: newSelelectionBase,
        extentDocumentPosition: newSelelectionExtent);
  }

  void _toggleAttributions(Set<Attribution> attributions) {
    final selection = composer.selection;
    if (selection == null) {
      return;
    }

    selection.isCollapsed
        ? commonOps.toggleComposerAttributions(attributions)
        : commonOps.toggleAttributionsOnSelection(attributions);
  }

  void _convertToParagraph() {
    commonOps.convertToParagraph();
  }

  void _convertToOrderedListItem() {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;

    if (selectedNode is ListItemNode &&
        selectedNode.type == ListItemType.ordered) {
      _convertToParagraph();
    } else {
      commonOps.convertToListItem(ListItemType.ordered, selectedNode.text);
    }
  }

  void _convertToUnorderedListItem() {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;

    if (selectedNode is ListItemNode &&
        selectedNode.type == ListItemType.unordered) {
      _convertToParagraph();
    } else {
      commonOps.convertToListItem(ListItemType.unordered, selectedNode.text);
    }
  }

  void _convertToTask() {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;
    var convertToTaskCmd =
        ConvertParagraphToTaskCommand(nodeId: selectedNode.id);

    _convertToParagraph();
    if (selectedNode is! TaskNode) {
      // ignore: invalid_use_of_protected_member
      commonOps.editor.executeCommand(convertToTaskCmd);
    }
  }

  void _closeKeyboard() {
    composer.selection = null;
  }

  @override
  Widget build(BuildContext context) {
    final selection = composer.selection;

    if (selection == null) {
      return const SizedBox();
    }

    final brightness =
        this.brightness ?? MediaQuery.of(context).platformBrightness;
    final selectedNode = document.getNodeById(selection.extent.nodeId);
    final isSingleNodeSelected =
        selection.extent.nodeId == selection.base.nodeId;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: brightness,
        disabledColor: brightness == Brightness.light
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.5),
      ),
      child: IconTheme(
        data: IconThemeData(
          color: brightness == Brightness.light ? Colors.black : Colors.white,
        ),
        child: Material(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 48,
            color: brightness == Brightness.light
                ? const Color(0xFFDDDDDD)
                : const Color(0xFF222222),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:
                              selectedNode is TextNode ? _addWikiLinks : null,
                          icon: const Icon(Icons.data_array),
                        ),
                        IconButton(
                          onPressed: selectedNode is TextNode ? _addTag : null,
                          icon: const Icon(Icons.tag),
                        ),
                        IconButton(
                          onPressed:
                              selectedNode is TextNode ? _toggleBold : null,
                          icon: const Icon(Icons.format_bold),
                          color: _isBoldActive
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        IconButton(
                          onPressed:
                              selectedNode is TextNode ? _toggleItalics : null,
                          icon: const Icon(Icons.format_italic),
                          color: _isItalicsActive
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        IconButton(
                          onPressed:
                              isSingleNodeSelected && selectedNode is TextNode
                                  ? _convertToOrderedListItem
                                  : null,
                          icon: const Icon(Icons.format_list_numbered),
                        ),
                        IconButton(
                          onPressed:
                              isSingleNodeSelected && selectedNode is TextNode
                                  ? _convertToUnorderedListItem
                                  : null,
                          icon: const Icon(Icons.format_list_bulleted),
                        ),
                        IconButton(
                          onPressed:
                              isSingleNodeSelected && selectedNode is TextNode
                                  ? _convertToTask
                                  : null,
                          icon: const Icon(Icons.checklist),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFCCCCCC),
                ),
                IconButton(
                  onPressed: _closeKeyboard,
                  icon: const Icon(Icons.keyboard_hide),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
