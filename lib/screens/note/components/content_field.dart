import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/link_suggestions.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/components/link_preview.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:flutter/services.dart';

class ContentField extends StatefulWidget {
  const ContentField({
    Key? key,
    required this.controller,
    required this.db,
    this.autofocus = false,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final Database db;
  final VoidCallback? onChanged;
  final bool autofocus;

  @override
  State<ContentField> createState() => _ContentFieldState();
}

class _ContentFieldState extends State<ContentField> {
  final ValueNotifier<String> titleLinkQuery = ValueNotifier('');
  final LayerLink layerLink = LayerLink();
  late final FocusNode contentFocusNode;
  OverlayEntry? overlayEntry = OverlayEntry(
    builder: (context) => Container(),
  );
  bool titleLinksVisible = false;

  @override
  void initState() {
    // NOTE: onKeyEvent doesn't ignore enter key press
    contentFocusNode = FocusNode(onKey: onKeyEvent);
    contentFocusNode.addListener(() {
      if (!contentFocusNode.hasFocus) {
        removeOverlay();
      }
    });
    super.initState();
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

  void _onContentChanged(context, text, size) {
    if (widget.onChanged != null) {
      widget.onChanged!();
    }
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
  }

  // Helper Functions
  bool isTitleLinksVisible(text) {
    var caretIndex = widget.controller.selection.baseOffset;
    int i = text.substring(0, caretIndex).lastIndexOf('[[');
    if (i == -1) return false;
    int nextI = text.indexOf('[', i + 2);
    nextI = (nextI > 0) ? nextI : text.length;
    return !text.substring(i, nextI).contains(']');
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
          t.substring(caretI, t.length);
      widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: linkIndex + link.length + 4));
      widget.db.firebase.analytics
          .logEvent(name: 'link_suggestion_select', parameters: {
        'query': beforeCaretText.substring(linkIndex).replaceAll('[', ''),
        'selected_link': link,
      });
      removeOverlay();
    }

    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyText2!,
      size,
    );
    List allLinks = await widget.db.getAllLinks();

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
      Note? note = await widget.db.getNoteByTitle(title);
      note ??= Note.empty(title: title);
      return note;
    }

    void _onFollowLinkTap(Note note) async {
      widget.db.navigateToNote(note); // TODO: Deprecate
      await widget.db.firebase.analytics.logEvent(name: 'follow_link');
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
        return TextField(
          focusNode: contentFocusNode,
          autofocus: widget.autofocus,
          controller: widget.controller,
          minLines: 5,
          maxLines: 10,
          style: Theme.of(context).textTheme.bodyText2,
          decoration: const InputDecoration(
            hintText: "Note and links to other ideas",
            border: InputBorder.none,
          ),
          onChanged: (text) => _onContentChanged(context, text, size),
          onTap: () => _onContentTap(context, size),
        );
      }),
    );
  }
}
