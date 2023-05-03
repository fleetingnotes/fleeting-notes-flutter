import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

const emptyAttribution = NamedAttribution('empty');
const wikilinkAttribution = NamedAttribution('wikilink');

TextStyle textStyleBuilder(Set<Attribution> attributions) {
  // We only care about altering a few styles. Start by getting
  // the standard styles for these attributions.
  var newStyle = defaultStyleBuilder(attributions);
  // makes it so we can see a cursor
  newStyle = newStyle.copyWith(
    color: Colors.black,
    fontSize: 14,
  );

  // Style headers
  for (final attribution in attributions) {
    if (attribution == emptyAttribution) {
      newStyle = newStyle.copyWith(
        color: const Color(0xFF444444),
        fontSize: 14,
      );
    } else if (attribution == wikilinkAttribution) {
      newStyle = newStyle.copyWith(
        color: Color(Colors.lightBlue.value),
      );
    }
  }

  return newStyle;
}

// https://github.com/superlistapp/super_editor/issues/861#issuecomment-1312222604
class EmptyHintComponentBuilder implements ComponentBuilder {
  const EmptyHintComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    if (node is! ParagraphNode) {
      return null;
    }
    // We only care about the situation where the Document is empty. In this case
    // a Document is "empty" when there is only a single ParagraphNode.
    if (document.nodes.length > 1) {
      return null;
    }
    // We only care about the situation where the first ParagraphNode is empty.
    if (node.text.text.isNotEmpty) {
      return null;
    }
    // This component builder can work with the standard paragraph view model.
    // We'll defer to the standard paragraph component builder to create it.
    return ParagraphComponentViewModel(
        nodeId: node.id,
        text: node.text,
        blockType: emptyAttribution,
        textStyleBuilder: textStyleBuilder,
        selectionColor: defaultSelectionStyle.selectionColor);
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ParagraphComponentViewModel) {
      return null;
    }

    final blockAttribution = componentViewModel.blockType;
    if (blockAttribution != emptyAttribution) {
      return null;
    }

    final textSelection = componentViewModel.selection;
    return TextWithHintComponent(
      key: componentContext.componentKey,
      text: componentViewModel.text,
      textStyleBuilder: textStyleBuilder,
      metadata: componentViewModel.blockType != null
          ? {
              'blockType': componentViewModel.blockType,
            }
          : {},
      // This is the text displayed as a hint.
      hintText: AttributedText(
        text: 'Start writing your thoughts...',
      ),
      // This is the function that selects styles for the hint text.
      hintStyleBuilder: (Set<Attribution> attributions) =>
          textStyleBuilder(attributions).copyWith(
        color: const Color(0xFFDDDDDD),
      ),
      textSelection: textSelection,
      selectionColor: componentViewModel.selectionColor,
    );
  }
}

class WikilinkComponentBuilder implements ComponentBuilder {
  const WikilinkComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    return null;
  }

  AttributedText highlightWikilinks(AttributedText attributedText) {
    attributedText = attributedText.copyText(0, attributedText.text.length);
    var matches = RegExp(Note.linkRegex).allMatches(attributedText.text);
    if (attributedText.text.isNotEmpty) {
      attributedText.removeAttribution(wikilinkAttribution,
          SpanRange(start: 0, end: attributedText.text.length - 1));
    }
    for (var m in matches) {
      attributedText.addAttribution(
          wikilinkAttribution, SpanRange(start: m.start, end: m.end - 1));
    }
    return attributedText;
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is ParagraphComponentViewModel) {
      return TextComponent(
        key: componentContext.componentKey,
        text: highlightWikilinks(componentViewModel.text),
        textStyleBuilder: textStyleBuilder,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
      );
    } else if (componentViewModel is ListItemComponentViewModel) {
      if (componentViewModel.type == ListItemType.ordered) {
        return OrderedListItemComponent(
          textKey: componentContext.componentKey,
          listIndex: componentViewModel.ordinalValue ?? 1,
          text: highlightWikilinks(componentViewModel.text),
          textSelection: componentViewModel.selection,
          selectionColor: componentViewModel.selectionColor,
          styleBuilder: textStyleBuilder,
          indent: componentViewModel.indent,
          highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        );
      } else if (componentViewModel.type == ListItemType.unordered) {
        return UnorderedListItemComponent(
          textKey: componentContext.componentKey,
          text: highlightWikilinks(componentViewModel.text),
          textSelection: componentViewModel.selection,
          selectionColor: componentViewModel.selectionColor,
          styleBuilder: textStyleBuilder,
          indent: componentViewModel.indent,
          highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        );
      }
    } else if (componentViewModel is TaskComponentViewModel) {
      componentViewModel.text = highlightWikilinks(componentViewModel.text);
      componentViewModel.textStyleBuilder = textStyleBuilder;
      return TaskComponent(
        viewModel: componentViewModel,
      );
    }
    return null;
  }
}

class TaskNodeSerializer extends DocumentNodeMarkdownSerializer {
  String doSerialization(Document document, TaskNode node) {
    final buffer = StringBuffer();

    final symbol = node.isComplete ? '- [x]' : '- [ ]';

    buffer.write('$symbol ${node.text.toMarkdown()}');

    final nodeIndex = document.getNodeIndexById(node.id);
    final nodeBelow = nodeIndex < document.nodes.length - 1
        ? document.nodes[nodeIndex + 1]
        : null;
    if (nodeBelow != null && nodeBelow is! TaskNode) {
      // This list item is the last item in the list. Add an extra
      // blank line after it.
      buffer.writeln('');
    }

    return buffer.toString();
  }

  @override
  String? serialize(Document document, DocumentNode node) {
    if (node is! TaskNode) {
      return null;
    }

    return doSerialization(document, node);
  }
}
