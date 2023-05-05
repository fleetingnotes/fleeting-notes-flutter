// Editor
// TODO: make the note properly populate the fields & save work as intended
// TODO: add checkboxes
// TODO: make link suggestions and link previews work
// TODO: Use docOps to appendText & handlePaste image from web
import 'dart:async';
import 'dart:math';

import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_suggestions.dart';
import 'package:fleeting_notes_flutter/screens/note/components/content_toolbar.dart';
import 'package:fleeting_notes_flutter/screens/note/components/super_editor_utils.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:pasteboard/pasteboard.dart';
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
  bool isPasting = false;
  StreamSubscription<Uint8List?>? pasteListener;

  List<String> allLinks = [];

  @override
  void initState() {
    final db = ref.read(dbProvider);
    final be = ref.read(browserExtensionProvider);
    pasteListener = be.pasteController.stream.listen((pasteImage) {
      if (contentFocusNode.hasFocus && !isPasting) {
        handlePaste(pasteImage: pasteImage, docOps: _docOps);
      }
    });

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
    pasteListener?.cancel();
    removeOverlay();
    super.dispose();
  }

  void onDocChange() async {
    widget.onChanged?.call();
  }

  void handlePaste(
      {Uint8List? pasteImage, CommonEditorOperations? docOps}) async {
    isPasting = true;
    final db = ref.read(dbProvider);
    try {
      pasteImage ??= await Pasteboard.image;
      if (pasteImage != null) {
        try {
          Note? newNote =
              await db.addAttachmentToNewNote(fileBytes: pasteImage);
          if (newNote != null) {
            docOps?.insertPlainText("[[${newNote.title}]]");
            widget.onChanged?.call();
          }
        } on FleetingNotesException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        throw FleetingNotesException('No Image to paste');
      }
    } catch (e) {
      // perform regular paste
      var clipboardData = await Clipboard.getData('text/plain');
      String? clipboardText = clipboardData?.text;
      if (clipboardText != null) {
        docOps?.insertPlainText(clipboardText);
        widget.onChanged?.call();
      }
    }
    isPasting = false;
  }

  ExecutionInstruction pasteWhenCmdVPressed({
    required EditContext editContext,
    required RawKeyEvent keyEvent,
  }) {
    if (keyEvent is! RawKeyDownEvent) {
      return ExecutionInstruction.continueExecution;
    }

    if (!keyEvent.isPrimaryShortcutKeyPressed ||
        keyEvent.logicalKey != LogicalKeyboardKey.keyV) {
      return ExecutionInstruction.continueExecution;
    }
    if (editContext.composer.selection == null) {
      return ExecutionInstruction.continueExecution;
    }

    if (!kIsWeb) {
      // if web, use paste listener (to handle paste from firefox)
      handlePaste(docOps: editContext.commonOps);
      return ExecutionInstruction.haltExecution;
    }
    // change to continueExectuion to trigger browser paste
    return ExecutionInstruction.continueExecution;
  }

  void onSelectionOverlay() async {
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
    if (selectedNode is TextNode) {
      var allTextNode = selectedNode.computeSelection(
          base: selectedNode.beginningPosition,
          extent: selectedNode.endPosition);
      var selectionTextNode = selectedNode.computeSelection(
          base: selection.base.nodePosition,
          extent: selection.extent.nodePosition);

      String allText = selectedNode.copyContent(allTextNode);

      // Link Preview Overlay
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
      } else {
        // Link Suggestion Overlay
        var caretOffset = min(selectionTextNode.baseOffset, allText.length);
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
      }
      // TODO: replace below with PGVector stuff
      final db = ref.read(dbProvider);
      var isPremium = await db.supabase.getSubscriptionTier() ==
          SubscriptionTier.premiumSub;
      if (allText.length % 30 == 0 && allText.isNotEmpty && isPremium) {
        db.textSimilarity
            .orderListByRelevance(allText, allLinks)
            .then((newLinkSuggestions) {
          allLinks = newLinkSuggestions;
        });
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
    Offset caretOffset = getOverlayBoundingBox().bottomCenter;
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
    if (selectedNode is TextNode) {
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
    Offset caretOffset = getOverlayBoundingBox().bottomCenter;
    Widget builder(context) {
      return ValueListenableBuilder(
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
          });
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

  List<Widget Function(FocusNode)> toolbarButtons(
      CommonEditorOperations docOps) {
    return [
      (node) {
        return ContentEditingToolbar(
            document: widget.doc, composer: _composer, commonOps: docOps);
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    _composer.selectionNotifier.removeListener(onSelectionOverlay);
    _composer.selectionNotifier.addListener(onSelectionOverlay);
    widget.doc.removeListener(onDocChange);
    widget.doc.addListener(onDocChange);
    final ed = ref.watch(editorProvider);
    final _docEditor = DocumentEditor(document: widget.doc);
    final _newDocOps = CommonEditorOperations(
      editor: _docEditor,
      composer: _composer,
      documentLayoutResolver: () =>
          _docLayoutKey.currentState as DocumentLayout,
    );
    _docOps = _newDocOps;
    ed.docOps = _docOps;
    return WillPopScope(
      onWillPop: () async {
        removeOverlay();
        return true;
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: KeyboardActions(
          enable: [TargetPlatform.iOS, TargetPlatform.android]
              .contains(defaultTargetPlatform),
          disableScroll: true,
          isDialog: true,
          config: KeyboardActionsConfig(
              keyboardBarColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                KeyboardActionsItem(
                  focusNode: contentFocusNode,
                  displayArrows: false,
                  displayDoneButton: false,
                  toolbarAlignment: MainAxisAlignment.spaceAround,
                  toolbarButtons: toolbarButtons(_newDocOps),
                ),
              ]),
          child: SuperEditor(
              documentLayoutKey: _docLayoutKey,
              keyboardActions: [
                toggleInteractionModeWhenCmdOrCtrlPressed,
                doNothingWhenThereIsNoSelection,
                pasteWhenCmdVPressed,
                copyWhenCmdCIsPressed,
                cutWhenCmdXIsPressed,
                collapseSelectionWhenEscIsPressed,
                selectAllWhenCmdAIsPressed,
                moveUpDownLeftAndRightWithArrowKeys,
                moveToLineStartWithHome,
                moveToLineEndWithEnd,
                tabToIndentListItem,
                shiftTabToUnIndentListItem,
                backspaceToUnIndentListItem,
                backspaceToClearParagraphBlockType,
                cmdBToToggleBold,
                cmdIToToggleItalics,
                shiftEnterToInsertNewlineInBlock,
                enterToInsertNewTask,
                enterToInsertBlockNewline,
                backspaceToRemoveUpstreamContent,
                deleteToRemoveDownstreamContent,
                moveToLineStartOrEndWithCtrlAOrE,
                deleteLineWithCmdBksp,
                deleteWordWithAltBksp,
                anyCharacterOrDestructiveKeyToDeleteSelection,
                anyCharacterToInsertInParagraph,
                anyCharacterToInsertInTextContent,
              ],
              editor: _docEditor,
              composer: _composer,
              autofocus: widget.autofocus,
              focusNode: contentFocusNode,
              stylesheet: Stylesheet(
                rules: defaultStylesheet.rules,
                inlineTextStyler:
                    (Set<Attribution> attributions, TextStyle existingStyle) {
                  return existingStyle.merge(
                    textStyleBuilder(attributions),
                  );
                },
                documentPadding: EdgeInsets.zero,
              ),
              componentBuilders: [
                const EmptyHintComponentBuilder(),
                WikilinkComponentBuilder(_docEditor),
                ...defaultComponentBuilders,
              ]),
        ),
      ),
    );
  }
}

bool linkSuggestionsVisible(String text, int caretIndex) {
  String lastLine = '';
  lastLine = text.substring(0, min(caretIndex, text.length)).split('\n').last;
  RegExp r = RegExp(r'\[\[((?!([\]])).)*$');
  bool showLinkSuggestions = r.hasMatch(lastLine);
  return showLinkSuggestions;
}
