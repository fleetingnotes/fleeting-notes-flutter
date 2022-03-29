import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/title_links.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/note/components/follow_link.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:provider/provider.dart';
import 'package:fleeting_notes_flutter/screens/main/state/note_stack_model.dart';

class ContentField extends StatefulWidget {
  const ContentField({
    Key? key,
    required this.controller,
    required this.db,
    this.autofocus = false,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final RealmDB db;
  final VoidCallback? onChanged;
  final bool autofocus;

  @override
  State<ContentField> createState() => _ContentFieldState();
}

class _ContentFieldState extends State<ContentField> {
  final ValueNotifier<String> titleLinkQuery = ValueNotifier('');
  final LayerLink layerLink = LayerLink();
  final FocusNode contentFocusNode = FocusNode();
  late OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Container(),
  );
  bool titleLinksVisible = false;

  @override
  void initState() {
    super.initState();

    contentFocusNode.addListener(() {
      removeOverlay();
    });
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
      titleLinkQuery.value = '';
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
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
              return TitleLinks(
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
    void _onFollowLinkTap() async {
      Note? note = await widget.db.getNoteByTitle(title);
      note ??= Note.empty(title: title);
      Provider.of<NoteStackModel>(context, listen: false)
              .pushNote(Note.empty());
      widget.db.navigateToNote(note); // TODO: Deprecate
    }

    // init overlay entry
    removeOverlay();
    Offset caretOffset = getCaretOffset(
      widget.controller,
      Theme.of(context).textTheme.bodyText2!,
      size,
    );
    FollowLink builder(context) {
      return FollowLink(
        caretOffset: caretOffset,
        onTap: _onFollowLinkTap,
        layerLink: layerLink,
      );
    }

    overlayContent(builder);
  }

  void overlayContent(builder) {
    OverlayState? overlayState = Overlay.of(context);
    overlayEntry = OverlayEntry(builder: builder);
    // show overlay
    if (overlayState != null) {
      overlayState.insert(overlayEntry);
    }
  }

  void removeOverlay() {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
      titleLinkQuery.value = '';
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
            hintText: "Note",
            border: InputBorder.none,
          ),
          onChanged: (text) => _onContentChanged(context, text, size),
          onTap: () => _onContentTap(context, size),
        );
      }),
    );
  }
}
