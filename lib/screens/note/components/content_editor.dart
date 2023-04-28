// Editor
// TODO: make the note properly populate the fields & save work as intended
// TODO: make the save & ntoe hist
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

class ContentEditor extends ConsumerStatefulWidget {
  const ContentEditor({
    super.key,
    this.autofocus = false,
    this.onChanged,
    this.onPop,
  });

  final bool autofocus;
  final VoidCallback? onChanged;
  final VoidCallback? onPop;

  @override
  ConsumerState<ContentEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<ContentEditor> {
  MutableDocument? doc;
  @override
  void initState() {
    final editorData = ref.read(editorProvider);
    var onChanged = widget.onChanged;
    doc = editorData.contentDoc;
    if (onChanged != null) {
      doc?.removeListener(onChanged);
      doc?.addListener(onChanged);
    }
    super.initState();
  }

  @override
  void dispose() {
    var onChanged = widget.onChanged;
    if (onChanged != null) {
      doc?.removeListener(onChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorData = ref.read(editorProvider);
    return SuperEditor(
        editor: DocumentEditor(document: editorData.contentDoc),
        autofocus: widget.autofocus,
        stylesheet: Stylesheet(
          rules: defaultStylesheet.rules,
          inlineTextStyler: defaultStylesheet.inlineTextStyler,
          documentPadding: EdgeInsets.zero,
        ),
        componentBuilders: [
          const EmptyHintComponentBuilder(),
          ...defaultComponentBuilders,
        ]);
  }
}

TextStyle _textStyleBuilder(Set<Attribution> attributions) {
  // We only care about altering a few styles. Start by getting
  // the standard styles for these attributions.
  var newStyle = defaultStyleBuilder(attributions);

  // Style headers
  for (final attribution in attributions) {
    if (attribution == emptyAttribution) {
      newStyle = newStyle.copyWith(
        color: const Color(0xFF444444),
        fontSize: 14,
      );
    }
  }

  return newStyle;
}

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
        textStyleBuilder: _textStyleBuilder,
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
      textStyleBuilder: _textStyleBuilder,
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
          _textStyleBuilder(attributions).copyWith(
        color: const Color(0xFFDDDDDD),
      ),
      textSelection: textSelection,
      selectionColor: componentViewModel.selectionColor,
    );
  }
}

const emptyAttribution = NamedAttribution('empty');
