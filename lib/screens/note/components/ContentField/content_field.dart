import 'dart:async';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/widgets/shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'keyboard_button.dart';
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
    this.autofocus = false,
    this.onChanged,
    this.onPop,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final VoidCallback? onPop;
  final bool autofocus;

  @override
  ConsumerState<ContentField> createState() => _ContentFieldState();
}

class _ContentFieldState extends ConsumerState<ContentField> {
  final ValueNotifier<String> titleLinkQuery = ValueNotifier('');
  List<String> allLinks = [];
  final LayerLink layerLink = LayerLink();
  late final FocusNode contentFocusNode;
  OverlayEntry? overlayEntry = OverlayEntry(
    builder: (context) => Container(),
  );
  bool titleLinksVisible = false;
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
    if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]
        .contains(e.logicalKey)) {
      removeOverlay();
    }
    return KeyEventResult.ignored;
  }

  // Widget Functions
  void _onContentTap(context, BoxConstraints size) async {
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
        showFollowLinkOverlay(context, title, size);
      }
    }
  }

  void _onContentChanged(context, text, size) async {
    final db = ref.read(dbProvider);
    widget.onChanged?.call();
    String beforeCaretText =
        text.substring(0, widget.controller.selection.baseOffset);

    bool isVisible = isTitleLinksVisible(text);
    if (isVisible) {
      if (!titleLinksVisible) {
        showTitleLinksOverlay(context, size);
        titleLinksVisible = true;
      } else {
        String query = beforeCaretText.substring(
            beforeCaretText.lastIndexOf('[[') + 2, beforeCaretText.length);
        titleLinkQuery.value = query;
      }
    } else {
      titleLinksVisible = false;
      removeOverlay();
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

  // Helper Functions
  bool isTitleLinksVisible(String text) {
    var caretIndex = widget.controller.selection.baseOffset;
    String lastLine = text.substring(0, caretIndex).split('\n').last;
    RegExp r = RegExp(r'\[\[((?!([\]])).)*$');
    bool showTitleLinks = r.hasMatch(lastLine);
    return showTitleLinks;
  }

  Offset getCaretOffset(TextEditingController textController,
      TextStyle? textStyle, BoxConstraints size) {
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
      painter.height + 10,
    );
  }

  // Overlay Functions
  void showTitleLinksOverlay(context, BoxConstraints size) async {
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
      size,
    );

    Widget builder(context) {
      // ignore: avoid_unnecessary_containers
      return Container(
        child: ValueListenableBuilder(
            valueListenable: titleLinkQuery,
            builder: (context, value, child) {
              return LinkSuggestions(
                caretOffset: caretOffset,
                allLinks: allLinks,
                query: titleLinkQuery.value,
                onLinkSelect: _onLinkSelect,
                layerLink: layerLink,
              );
            }),
      );
    }

    overlayContent(builder);
  }

  void showFollowLinkOverlay(context, String title, BoxConstraints size) async {
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
      size,
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
      titleLinkQuery.value = '';
      overlayEntry = null;
    }
  }

  List<Widget Function(FocusNode)> toolbarButtons(BoxConstraints size) {
    return [
      (node) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                KeyboardButton(
                  icon: Icons.data_array,
                  onPressed: () {
                    shortcuts.action('[[', ']]');
                    _onContentChanged(context, widget.controller.text, size);
                  },
                  tooltip: 'Add link',
                ),
                KeyboardButton(
                  icon: Icons.tag,
                  onPressed: () {
                    shortcuts.action('#', '');
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.format_bold,
                  onPressed: () {
                    shortcuts.action('**', '**');
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.format_italic,
                  onPressed: () {
                    shortcuts.action('*', '*');
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.add_link,
                  onPressed: () {
                    shortcuts.addLink();
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.list,
                  onPressed: () {
                    shortcuts.toggleList();
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.checklist_outlined,
                  onPressed: () {
                    shortcuts.toggleCheckbox();
                    _onContentChanged(context, widget.controller.text, size);
                  },
                ),
                KeyboardButton(
                  icon: Icons.cancel_outlined,
                  onPressed: contentFocusNode.unfocus,
                ),
              ],
            ),
          ),
        );
      }
    ];
  }

  Map<Type, Action<Intent>> getTextFieldActions(BoxConstraints size) {
    return {
      BoldIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.action('**', '**');
        return _onContentChanged(context, widget.controller.text, size);
      }),
      ItalicIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.action('*', '*');
        return _onContentChanged(context, widget.controller.text, size);
      }),
      AddLinkIntent: CallbackAction(onInvoke: (Intent intent) {
        shortcuts.addLink();
        return _onContentChanged(context, widget.controller.text, size);
      }),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: LayoutBuilder(builder: (context, size) {
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
                    toolbarButtons: toolbarButtons(size),
                  ),
                ]),
            child: Actions(
              actions: getTextFieldActions(size),
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
                onChanged: (text) => _onContentChanged(context, text, size),
                onTap: () => _onContentTap(context, size),
              ),
            ),
          ),
        );
      }),
    );
  }
}
