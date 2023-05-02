// Editor
// TODO: make the note properly populate the fields & save work as intended
// TODO: add checkboxes
// TODO: make link suggestions and link previews work
// TODO: Use docOps to appendText & handlePaste image from web
import 'dart:math';

import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_suggestions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
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
  CommonEditorOperations? _docOps;
  OverlayEntry? _overlayEntry;
  final LayerLink layerLink = LayerLink();
  final ValueNotifier<String?> linkSuggestionQuery = ValueNotifier(null);
  final FocusNode contentFocusNode = FocusNode();

  List<String> allLinks = [];

  @override
  void initState() {
    final db = ref.read(dbProvider);
    _composer.selectionNotifier.removeListener(onSelectionOverlay);
    _composer.selectionNotifier.addListener(onSelectionOverlay);

    widget.doc.removeListener(onDocChange);
    widget.doc.addListener(onDocChange);
    db.getAllLinks().then((links) {
      if (!mounted) return;
      allLinks = links;
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.doc.removeListener(onDocChange);
    _composer.dispose();
    removeOverlay();
    super.dispose();
  }

  void onDocChange() async {
    widget.onChanged?.call();
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

    // TODO: check that this works with lists & tasks
    if (selectedNode is ParagraphNode) {
      var allTextNode = selectedNode.computeSelection(
          base: selectedNode.beginningPosition,
          extent: selectedNode.endPosition);
      var selectionTextNode = selectedNode.computeSelection(
          base: selection.base.nodePosition,
          extent: selection.extent.nodePosition);

      String allText = selectedNode.copyContent(allTextNode);

      var caretOffset = min(selectionTextNode.baseOffset + 1, allText.length);
      bool isVisible = linkSuggestionsVisible(allText, caretOffset);
      if (isVisible) {
        if (linkSuggestionQuery.value == null) {
          linkSuggestionQuery.value = '';
          showLinkSuggestionsOverlay();
        } else {
          String beforeCaretText = allText.substring(0, caretOffset);
          String query = beforeCaretText.substring(
              beforeCaretText.lastIndexOf('[[') + 2, beforeCaretText.length);
          linkSuggestionQuery.value = query;
        }
      } else {
        linkSuggestionQuery.value = null;
        removeOverlay();
      }
      // TODO: replace below with PGVector stuff
      final db = ref.read(dbProvider);
      var isPremium = await db.supabase.getSubscriptionTier() ==
          SubscriptionTier.premiumSub;
      if (allText.length % 30 == 0 && allText.isNotEmpty && isPremium) {
        db.textSimilarity
            .orderListByRelevance(allText, allLinks)
            .then((newLinkSuggestions) {
          if (!mounted) return;
          setState(() {
            allLinks = newLinkSuggestions;
          });
        });
      }
    }
  }

  void onSelectionOverlay() {
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
    // TODO: check that this works with lists & tasks
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
        var m = filteredMatches.first;
        String? title = m.group(1);
        if (title != null) {
          showFollowLinkOverlay(title);
        }
      } else if (linkSuggestionQuery.value == null) {
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

  // handles linkSelect
  _onLinkSelect(String link) {
    var selection = _composer.selection;
    if (selection == null) {
      linkSuggestionQuery.value = null;
      removeOverlay();
      return;
    }

    final selectedNode = widget.doc.getNodeById(selection.base.nodeId);
    if (selectedNode == null) {
      linkSuggestionQuery.value = null;
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
      String beforeCaretText = selectionTextNode.textBefore(allText);
      int linkIndex = beforeCaretText.lastIndexOf('[[');
      String insertText = link;

      if (!selectionTextNode.textAfter(allText).startsWith(']]')) {
        insertText += ']]';
      }

      _docOps?.selectRegion(
          baseDocumentPosition: DocumentPosition(
              nodeId: selectedNode.id,
              nodePosition: TextNodePosition(offset: linkIndex + 2)),
          extentDocumentPosition: DocumentPosition(
              nodeId: selectedNode.id,
              nodePosition: TextNodePosition(
                  offset: linkIndex +
                      2 +
                      (linkSuggestionQuery.value?.length ?? 0))));
      _docOps?.deleteSelection();
      _docOps?.insertPlainText(insertText);
      var docPos = DocumentPosition(
          nodeId: selectedNode.id,
          nodePosition: TextNodePosition(offset: linkIndex + 4 + link.length));
      _docOps?.selectRegion(
          baseDocumentPosition: docPos, extentDocumentPosition: docPos);
    }
    widget.onChanged?.call();
    linkSuggestionQuery.value = null;
    removeOverlay();
  }

  void showLinkSuggestionsOverlay() async {
    removeOverlay();
    Offset caretOffset = getOverlayBoundingBox().bottomLeft;
    Widget builder(context) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: ValueListenableBuilder(
            valueListenable: linkSuggestionQuery,
            builder: (context, _, __) {
              final val = linkSuggestionQuery.value;
              if (val == null) return const SizedBox.shrink();
              return LinkSuggestions(
                caretOffset: caretOffset,
                allLinks: allLinks,
                query: val,
                onLinkSelect: _onLinkSelect,
                layerLink: layerLink,
                focusNode: contentFocusNode,
              );
            }),
      );
    }

    overlayContent(builder);
  }

  Rect getOverlayBoundingBox() {
    final selection = _composer.selection;
    var rect = const Rect.fromLTRB(0, 0, 0, 0);
    if (selection == null) return rect;

    // Note: we start at offset 0 so selection isnt "collapsed". This way it gives a proper rect.
    rect = (_docLayoutKey.currentState as DocumentLayout).getRectForSelection(
            DocumentPosition(
                nodeId: selection.base.nodeId,
                nodePosition: const TextNodePosition(offset: 0)),
            selection.extent) ??
        rect;
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
    final _docEditor = DocumentEditor(document: widget.doc);
    _docOps = CommonEditorOperations(
      editor: _docEditor,
      composer: _composer,
      documentLayoutResolver: () =>
          _docLayoutKey.currentState as DocumentLayout,
    );
    return WillPopScope(
      onWillPop: () async {
        removeOverlay();
        return true;
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: SuperEditor(
            documentLayoutKey: _docLayoutKey,
            editor: _docEditor,
            composer: _composer,
            autofocus: widget.autofocus,
            focusNode: contentFocusNode,
            stylesheet: Stylesheet(
              rules: defaultStylesheet.rules,
              inlineTextStyler:
                  (Set<Attribution> attributions, TextStyle existingStyle) {
                return existingStyle.merge(
                  _textStyleBuilder(attributions),
                );
              },
              documentPadding: EdgeInsets.zero,
            ),
            componentBuilders: [
              const WikilinkComponentBuilder(),
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

class WikilinkComponentBuilder implements ComponentBuilder {
  const WikilinkComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    return null;
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    AttributedText? attributedText;
    if (componentViewModel is ParagraphComponentViewModel) {
      attributedText = componentViewModel.text;
    } else if (componentViewModel is ListItemComponentViewModel) {
      attributedText = componentViewModel.text;
    }

    if (attributedText == null) return null;
    var matches = RegExp(Note.linkRegex).allMatches(attributedText.text);
    for (var m in matches) {
      attributedText.addAttribution(
          wikilinkAttribution, SpanRange(start: m.start, end: m.end - 1));
    }
    return null;
  }
}

const emptyAttribution = NamedAttribution('empty');
const wikilinkAttribution = NamedAttribution('wikilink');
bool linkSuggestionsVisible(String text, int caretIndex) {
  String lastLine = '';
  lastLine = text.substring(0, min(caretIndex, text.length)).split('\n').last;
  RegExp r = RegExp(r'\[\[((?!([\]])).)*$');
  bool showLinkSuggestions = r.hasMatch(lastLine);
  return showLinkSuggestions;
}
