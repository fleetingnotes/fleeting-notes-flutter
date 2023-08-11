import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/textfield_toolbar.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import '../../../../utils/shortcut_actions.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_suggestions.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/components/ContentField/link_preview.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class ContentField extends ConsumerStatefulWidget {
  const ContentField({
    Key? key,
    required this.controller,
    this.onCommandRun,
    this.autofocus = false,
    this.onChanged,
    this.onPop,
    this.textDirection = TextDirection.ltr,
  }) : super(key: key);

  final TextEditingController controller;
  final Function(String)? onCommandRun;
  final VoidCallback? onChanged;
  final VoidCallback? onPop;
  final bool autofocus;
  final TextDirection textDirection;

  @override
  ConsumerState<ContentField> createState() => _ContentFieldState();
}

class _ContentFieldState extends ConsumerState<ContentField> {
  final ValueNotifier<String?> titleLinkQuery = ValueNotifier(null);
  final ValueNotifier<String?> tagQuery = ValueNotifier(null);
  final ValueNotifier<String?> commandQuery = ValueNotifier(null);
  List<String> allLinks = [];
  List<String> allTags = [];
  BoxConstraints layoutSize = const BoxConstraints();
  final LayerLink layerLink = LayerLink();
  late final FocusNode contentFocusNode;
  OverlayEntry? overlayEntry = OverlayEntry(
    builder: (context) => Container(),
  );
  bool isPasting = false;
  StreamSubscription<Uint8List?>? pasteListener;

  late ShortcutActions shortcuts;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    final be = ref.read(browserExtensionProvider);
    pasteListener = be.pasteController.stream.listen((pasteImage) {
      if (contentFocusNode.hasFocus && !isPasting) {
        handlePaste(pasteImage: pasteImage);
      }
    });
    // NOTE: onKeyEvent doesn't ignore enter key press
    contentFocusNode = FocusNode(onKey: onKeyEvent);
    shortcuts = ShortcutActions(
      controller: widget.controller,
      bringEditorToFocus: contentFocusNode.requestFocus,
    );
    db.getAllTags().then((tags) {
      if (!mounted) return;
      setState(() {
        allTags = tags;
      });
    });
    db.getAllLinks().then((links) {
      if (!mounted) return;
      setState(() {
        allLinks = links;
      });
    });
  }

  void handlePaste({Uint8List? pasteImage}) async {
    setState(() {
      isPasting = true;
    });
    final db = ref.read(dbProvider);
    try {
      pasteImage ??= await Pasteboard.image;
      if (pasteImage != null) {
        try {
          Note? newNote =
              await db.addAttachmentToNewNote(fileBytes: pasteImage);
          if (newNote != null) {
            db.insertTextAtSelection(widget.controller, "[[${newNote.title}]]");
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
        db.insertTextAtSelection(widget.controller, clipboardText);
        widget.onChanged?.call();
      }
    }
    setState(() {
      isPasting = false;
    });
  }

  @override
  void dispose() {
    removeOverlay();
    contentFocusNode.dispose();
    pasteListener?.cancel();
    super.dispose();
  }

  KeyEventResult onKeyEvent(node, e) {
    if (e is! RawKeyDownEvent) return KeyEventResult.ignored;
    if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]
        .contains(e.logicalKey)) {
      removeOverlay();
    }
    return KeyEventResult.ignored;
  }

  // Widget Functions
  void _onContentTap() async {
    removeOverlay();
    // check if caretOffset is in a link
    var caretIndex = widget.controller.selection.baseOffset;
    var matches = RegExp(Note.linkRegex).allMatches(widget.controller.text);
    Iterable<RegExpMatch> filteredMatches =
        matches.where((m) => m.start < caretIndex && m.end > caretIndex);

    if (filteredMatches.isNotEmpty) {
      String? title = filteredMatches.first.group(1);
      if (title != null) {
        bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        if (!keyboardVisible) {
          contentFocusNode.unfocus();
        }
        showFollowLinkOverlay(title);
      }
    }
  }

  void tagSuggestionsOnChange(String text, TextSelection selection) async {
    var tempTagQuery = getTagQuery(text, selection.baseOffset);
    if (tempTagQuery != null &&
        (tagQuery.value == null || overlayEntry == null)) {
      showTagSuggestionsOverlay();
    }
    tagQuery.value = tempTagQuery;
  }

  void slashCommandsOnChange(String text, TextSelection selection) async {
    var tempCommandQuery = getCommandQuery(text, selection.baseOffset);
    if (tempCommandQuery != null &&
        (commandQuery.value == null || overlayEntry == null)) {
      showSlashCommandSuggestionsOverlay();
    }
    commandQuery.value = tempCommandQuery;
  }

  void linkSuggestionsOnChange(String text, TextSelection selection) async {
    final db = ref.read(dbProvider);
    bool isVisible = isTitleLinksVisible(text);
    String beforeCaretText = text.substring(0, selection.baseOffset);
    if (isVisible) {
      if (titleLinkQuery.value == null) {
        showTitleLinksOverlay();
        titleLinkQuery.value = '';
      } else {
        String query = beforeCaretText.substring(
            beforeCaretText.lastIndexOf('[[') + 2, beforeCaretText.length);
        titleLinkQuery.value = query;
      }
    } else {
      titleLinkQuery.value = null;
    }
    var isPremium =
        await db.supabase.getSubscriptionTier() == SubscriptionTier.premiumSub;
    if (widget.controller.text.length % 30 == 0 &&
        widget.controller.text.isNotEmpty &&
        isPremium) {
      db.textSimilarity
          .orderListByRelevance(widget.controller.text, allLinks)
          .then((newLinkSuggestions) {
        if (!mounted) return;
        setState(() {
          allLinks = newLinkSuggestions;
        });
      });
    }
  }

  void _onContentChanged(text) async {
    final db = ref.read(dbProvider);
    widget.onChanged?.call();
    linkSuggestionsOnChange(text, widget.controller.selection);
    tagSuggestionsOnChange(text, widget.controller.selection);
    if (db.loggedIn) {
      slashCommandsOnChange(text, widget.controller.selection);
    }
  }

  // Helper Functions
  bool isTitleLinksVisible(String text) {
    var caretIndex = widget.controller.selection.baseOffset;
    String lastLine = text.substring(0, caretIndex).split('\n').last;
    RegExp r = RegExp(r'\[\[((?!([\]])).)*$');
    bool showTitleLinks = r.hasMatch(lastLine);
    return showTitleLinks;
  }

  String? getTagQuery(String text, int caretIndex) {
    String beforeCaretText = text.substring(0, caretIndex);
    RegExp r = RegExp(Note.tagRegex, multiLine: true);
    var matches = r.allMatches(beforeCaretText);
    RegExpMatch? lastMatch = (matches.isEmpty) ? null : matches.last;
    if (lastMatch?.end == caretIndex) {
      return lastMatch?.group(2);
    }
    return null;
  }

  String? getCommandQuery(String text, int caretIndex) {
    String beforeCaretText = text.substring(0, caretIndex);
    RegExp r = RegExp(Note.commandRegex, multiLine: true);
    var matches = r.allMatches(beforeCaretText);
    RegExpMatch? lastMatch = (matches.isEmpty) ? null : matches.last;
    if (lastMatch?.end == caretIndex) {
      return lastMatch?.group(2);
    }
    return null;
  }

  Offset getCaretOffset(
      TextEditingController textController, TextStyle? textStyle,
      {BoxConstraints? size}) {
    size = size ?? layoutSize;
    String beforeCaretText =
        textController.text.substring(0, textController.selection.baseOffset);

    TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: textStyle,
        text: beforeCaretText,
      ),
    );
    painter.layout(maxWidth: size.maxWidth);

    return Offset(
      painter.computeLineMetrics().last.width,
      painter.height + 12,
    );
  }

  // Overlay Functions
  void showSlashCommandSuggestionsOverlay() async {
    _onCommandSelect(String alias) async {
      String t = widget.controller.text;
      int caretI = widget.controller.selection.baseOffset;
      String beforeCaretText = t.substring(0, caretI);
      int slashIndex = beforeCaretText.lastIndexOf('/');
      widget.controller.text =
          t.substring(0, slashIndex) + t.substring(caretI, t.length);
      widget.controller.selection =
          TextSelection.fromPosition(TextPosition(offset: slashIndex));
      widget.onCommandRun?.call(alias);
      widget.onChanged?.call();
      removeOverlay();
    }

    removeOverlay();
    final settings = ref.read(settingsProvider);
    List<String> commandSuggestions =
        (settings.get('plugin-slash-commands') as List? ?? [])
            .map((v) => v['alias'] as String? ?? '')
            .toList();
    commandSuggestions.removeWhere((q) => q.isEmpty);

    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyMedium,
    );

    Widget builder(context) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: ValueListenableBuilder<String?>(
            valueListenable: commandQuery,
            builder: (context, val, child) {
              final tempCommandQuery = commandQuery.value;
              if (tempCommandQuery == null) return const SizedBox.shrink();
              return Suggestions(
                  caretOffset: caretOffset,
                  suggestions: commandSuggestions,
                  query: tempCommandQuery,
                  onSelect: _onCommandSelect,
                  layerLink: layerLink);
            }),
      );
    }

    overlayContent(builder);
  }

  void showTagSuggestionsOverlay() async {
    _onTagSelect(String tag) {
      String t = widget.controller.text;
      int caretI = widget.controller.selection.baseOffset;
      String beforeCaretText = t.substring(0, caretI);
      int tagIndex = beforeCaretText.lastIndexOf('#');
      widget.controller.text =
          t.substring(0, tagIndex) + '#$tag' + t.substring(caretI, t.length);
      widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: tagIndex + tag.length + 1));
      widget.onChanged?.call();
      tagQuery.value = null;
      removeOverlay();
    }

    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyMedium,
    );

    Widget builder(context) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: ValueListenableBuilder<String?>(
            valueListenable: tagQuery,
            builder: (context, val, child) {
              final tempTagQuery = tagQuery.value;
              if (tempTagQuery == null) return const SizedBox.shrink();
              return Suggestions(
                  caretOffset: caretOffset,
                  suggestions: allTags,
                  query: tempTagQuery,
                  onSelect: _onTagSelect,
                  layerLink: layerLink);
            }),
      );
    }

    overlayContent(builder);
  }

  void showTitleLinksOverlay() async {
    _onLinkSelect(String link) {
      String t = widget.controller.text;
      int caretI = widget.controller.selection.baseOffset;
      String beforeCaretText = t.substring(0, caretI);
      int linkIndex = beforeCaretText.lastIndexOf('[[');
      widget.controller.text = t.substring(0, linkIndex) +
          '[[$link]]' +
          t.substring(caretI, t.length).replaceFirst(RegExp(r"^\]\]"), "");
      widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: linkIndex + link.length + 4));
      widget.onChanged?.call();
      removeOverlay();
    }

    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyMedium,
    );

    Widget builder(context) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: ValueListenableBuilder(
            valueListenable: titleLinkQuery,
            builder: (context, value, child) {
              final query = titleLinkQuery.value;
              if (query == null) return const SizedBox.shrink();
              return Suggestions(
                caretOffset: caretOffset,
                suggestions: allLinks,
                query: query,
                onSelect: _onLinkSelect,
                layerLink: layerLink,
              );
            }),
      );
    }

    overlayContent(builder);
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
      contentFocusNode.unfocus();
      removeOverlay();
      widget.onPop?.call();
      noteHistory.addNote(context, note);
    }

    // init overlay entry
    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyMedium,
    );
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

  void overlayContent(builder) {
    OverlayState? overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(builder: builder);
    // show overlay
    overlayState.insert(overlayEntry ?? OverlayEntry(builder: builder));
  }

  void removeOverlay() {
    if (overlayEntry != null && overlayEntry?.mounted == true) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  List<Widget Function(FocusNode)> toolbarButtons() {
    return [
      (node) {
        return TextFieldToolbar(
          shortcuts: shortcuts,
          controller: widget.controller,
          onContentChanged: _onContentChanged,
          unfocus: contentFocusNode.unfocus,
        );
      }
    ];
  }

  Map<Type, Action<Intent>> getTextFieldActions() {
    return {
      BoldIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.action('**', '**');
        return _onContentChanged(widget.controller.text);
      }),
      ItalicIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.action('*', '*');
        return _onContentChanged(widget.controller.text);
      }),
      AddLinkIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.addLink();
        return _onContentChanged(widget.controller.text);
      }),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: LayoutBuilder(builder: (context, size) {
        layoutSize = size;
        return WillPopScope(
          onWillPop: () async {
            removeOverlay();
            return true;
          },
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
                    toolbarButtons: toolbarButtons(),
                  ),
                ]),
            child: Actions(
              actions: getTextFieldActions(),
              child: TextField(
                focusNode: contentFocusNode,
                textCapitalization: TextCapitalization.sentences,
                autofocus: widget.autofocus,
                controller: widget.controller,
                keyboardType: TextInputType.multiline,
                minLines: 10,
                maxLines: null,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  hintText: "Start writing your thoughts...",
                  border: InputBorder.none,
                ),
                onChanged: (text) => _onContentChanged(text),
                onTap: () => _onContentTap(),
                textDirection: widget.textDirection,
              ),
            ),
          ),
        );
      }),
    );
  }
}
