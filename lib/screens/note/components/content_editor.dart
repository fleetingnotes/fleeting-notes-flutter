// Editor
// TODO: make the note properly populate the fields & save work as intended
// TODO: add checkboxes
// TODO: make link suggestions and link previews work
// TODO: make the save & ntoe hist
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';

class ContentEditor extends ConsumerStatefulWidget {
  const ContentEditor({
    super.key,
    required this.doc,
    this.autofocus = false,
    this.onChanged,
    this.onPop,
  });

  final bool autofocus;
  final VoidCallback? onChanged;
  final VoidCallback? onPop;
  final MutableDocument doc;

  @override
  ConsumerState<ContentEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<ContentEditor> {
  final GlobalKey _docLayoutKey = GlobalKey();
  final DocumentComposer _composer = DocumentComposer();
  OverlayEntry? _overlayEntry;
  final LayerLink layerLink = LayerLink();

  @override
  void initState() {
    _composer.selectionNotifier.addListener(_hideOrShowOverlay);
    var onChanged = widget.onChanged;
    if (onChanged != null) {
      widget.doc.removeListener(onChanged);
      widget.doc.addListener(onChanged);
    }
    super.initState();
  }

  @override
  void dispose() {
    var onChanged = widget.onChanged;
    if (onChanged != null) {
      widget.doc.removeListener(onChanged);
    }
    _composer.dispose();
    removeOverlay();
    super.dispose();
  }

  void _hideOrShowOverlay() {
    final selection = _composer.selection;
    if (selection == null) {
      removeOverlay();
      return;
    }
    final editorData = ref.read(editorProvider);
    final selectedNode =
        editorData.contentDoc.getNodeById(selection.extent.nodeId);
    if (selectedNode == null || !selection.isCollapsed) {
      removeOverlay();
      return;
    }
    if (selection.base.nodeId != selection.extent.nodeId) {
      // More than one node is selected. We don't want to show
      // a toolbar in this case.
      removeOverlay();
      return;
    }
    if (selectedNode is ParagraphNode) {
      var allTextNode = selectedNode.computeSelection(
          base: selectedNode.beginningPosition,
          extent: selectedNode.endPosition);
      var selectionTextNode = selectedNode.computeSelection(
          base: selection.base.nodePosition,
          extent: selection.extent.nodePosition);

      String allText = selectedNode.copyContent(allTextNode);

      var matches = RegExp(Note.linkRegex).allMatches(allText);
      Iterable<RegExpMatch> filteredMatches = matches.where((m) =>
          m.start < selectionTextNode.baseOffset &&
          m.start < selectionTextNode.extentOffset &&
          m.end > selectionTextNode.baseOffset &&
          m.end > selectionTextNode.extentOffset);
      if (filteredMatches.isNotEmpty) {
        String? title = filteredMatches.first.group(1);
        removeOverlay();
        if (title != null) {
          // bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
          // if (!keyboardVisible) {
          //   contentFocusNode.unfocus();
          // }
          showFollowLinkOverlay(title);
        }
      } else {
        removeOverlay();
      }
    }
  }

  void showFollowLinkOverlay(String title) async {
    Future<Note> getFollowLinkNote() async {
      final db = ref.read(dbProvider);
      Note? note = await db.getNoteByTitle(title);
      note ??= Note.empty(title: title);
      return note;
    }

    void _onFollowLinkTap(Note note) async {
      final noteHistory = ref.read(noteHistoryProvider.notifier);
      removeOverlay();
      widget.onPop?.call();
      noteHistory.addNote(context, note);
    }

    // init overlay entry
    removeOverlay();
    Offset caretOffset = getOverlayBoundingBox().bottomLeft;
    Widget builder(context) {
      return FutureBuilder<Note>(
          future: getFollowLinkNote(),
          builder: (BuildContext context, AsyncSnapshot<Note> snapshot) {
            var note = snapshot.data;
            if (note != null) {
              return LinkPreview(
                note: note,
                caretOffset: caretOffset,
                onTap: () => _onFollowLinkTap(note),
                layerLink: layerLink,
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    }

    overlayContent(builder);
  }

  Rect getOverlayBoundingBox() {
    final selection = _composer.selection;
    var rect = const Rect.fromLTRB(0, 0, 0, 0);
    if (selection == null) return rect;
    rect = (_docLayoutKey.currentState as DocumentLayout)
            .getRectForSelection(selection.base, selection.extent) ??
        rect;
    if (selection.isCollapsed) {
      rect = rect.shift(Offset(0, 25)); // dependent on font size here
    }
    return rect;
  }

  void overlayContent(Widget Function(BuildContext) builder) {
    OverlayState? overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: builder);
    // show overlay
    overlayState.insert(_overlayEntry ?? OverlayEntry(builder: builder));
  }

  void removeOverlay() {
    if (_overlayEntry != null && _overlayEntry?.mounted == true) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        removeOverlay();
        return true;
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: SuperEditor(
            documentLayoutKey: _docLayoutKey,
            editor: DocumentEditor(document: widget.doc),
            composer: _composer,
            autofocus: widget.autofocus,
            stylesheet: Stylesheet(
              rules: defaultStylesheet.rules,
              inlineTextStyler: defaultStylesheet.inlineTextStyler,
              documentPadding: EdgeInsets.zero,
            ),
            componentBuilders: [
              const EmptyHintComponentBuilder(),
              ...defaultComponentBuilders,
            ]),
      ),
    );
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
