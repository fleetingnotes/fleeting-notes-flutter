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
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
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
  late ShortcutActions shortcuts;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    // NOTE: onKeyEvent doesn't ignore enter key press
    contentFocusNode = FocusNode(onKey: onKeyEvent);
    contentFocusNode.addListener(() {
      if (!contentFocusNode.hasFocus) {
        removeOverlay();
      }
    });
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

  void handlePaste() async {
    setState(() {
      isPasting = true;
    });
    final db = ref.read(dbProvider);
    try {
      var pasteImage = await Pasteboard.image;
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
    super.dispose();
    contentFocusNode.dispose();
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
    Iterable<dynamic> filteredMatches =
        matches.where((m) => m.start < caretIndex && m.end > caretIndex);

    if (filteredMatches.isNotEmpty) {
      String title = filteredMatches.first.group(1);

      showFollowLinkOverlay(context, title, size);
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
      TextStyle textStyle, BoxConstraints size) {
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
      removeOverlay();
    }

    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyText2!,
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
      final db = ref.read(dbProvider);
      db.navigateToNote(note); // TODO: Deprecate
      removeOverlay();
    }

    // init overlay entry
    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyText2!,
      size,
    );
    Widget builder(context) {
      return FutureBuilder<Note>(
          future: getFollowLinkNote(),
          builder: (BuildContext context, AsyncSnapshot<Note> snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return LinkPreview(
                note: snapshot.data!,
                caretOffset: caretOffset,
                onTap: () => _onFollowLinkTap(snapshot.data!),
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
    if (overlayState != null) {
      overlayState.insert(overlayEntry!);
    }
  }

  void removeOverlay() {
    if (overlayEntry != null && overlayEntry!.mounted) {
      overlayEntry!.remove();
      titleLinkQuery.value = '';
      overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: LayoutBuilder(builder: (context, size) {
        return KeyboardActions(
          enable: defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS,
          disableScroll: true,
          config: KeyboardActionsConfig(
              keyboardBarColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                KeyboardActionsItem(
                  focusNode: contentFocusNode,
                  displayArrows: false,
                  displayDoneButton: false,
                  toolbarAlignment: MainAxisAlignment.spaceAround,
                  toolbarButtons: [
                    (node) {
                      return KeyboardButton(
                        icon: '[]',
                        onPressed: () {
                          shortcuts.addLink();
                          _onContentChanged(
                              context, widget.controller.text, size);
                        },
                        tooltip: 'Add link',
                      );
                    },
                    (node) {
                      return KeyboardButton(
                        icon: '#',
                        onPressed: () {
                          shortcuts.addTag();
                          _onContentChanged(
                              context, widget.controller.text, size);
                        },
                      );
                    },
                    (node) {
                      return KeyboardButton(
                        icon: Icons.checklist_outlined,
                        onPressed: () {
                          shortcuts.toggleCheckbox();
                          _onContentChanged(
                              context, widget.controller.text, size);
                        },
                      );
                    },
                    (node) {
                      return const KeyboardButton(
                        icon: 'Aa',
                        disabled: true,
                      );
                    },
                  ],
                )
              ]),
          child: Actions(
            actions: <Type, Action<Intent>>{
              PasteIntent: CallbackAction(onInvoke: (Intent intent) {
                if (!isPasting) handlePaste();
              }),
            },
            child: TextField(
              focusNode: contentFocusNode,
              textCapitalization: TextCapitalization.sentences,
              autofocus: widget.autofocus,
              controller: widget.controller,
              keyboardType: TextInputType.multiline,
              minLines: 5,
              maxLines: null,
              style: Theme.of(context).textTheme.bodyText2,
              decoration: const InputDecoration(
                hintText: "Note and links to other ideas",
                border: InputBorder.none,
              ),
              onChanged: (text) => _onContentChanged(context, text, size),
              onTap: () => _onContentTap(context, size),
            ),
          ),
        );
      }),
    );
  }
}
