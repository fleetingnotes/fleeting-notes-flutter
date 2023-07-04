import 'dart:async';

import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/exceptions.dart';
import '../../../../models/url_metadata.dart';

class SourceContainer extends ConsumerStatefulWidget {
  const SourceContainer({
    Key? key,
    this.controller,
    this.text,
    this.metadata,
    this.onChanged,
    this.onClearSource,
    this.readOnly = false,
    this.textDirection = TextDirection.ltr,
  }) : super(key: key);

  final String? text;
  final UrlMetadata? metadata;
  final TextEditingController? controller;
  final VoidCallback? onChanged;
  final VoidCallback? onClearSource;
  final bool readOnly;
  final TextDirection textDirection;

  @override
  ConsumerState<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends ConsumerState<SourceContainer> {
  TextEditingController controller = TextEditingController();
  Timer? saveTimer;
  StreamSubscription<Uint8List?>? pasteListener;
  FocusNode focusNode = FocusNode();
  bool isPasting = false;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? controller;
    final sourceUrl = widget.text ?? controller.text;
    controller.text = sourceUrl;
    final be = ref.read(browserExtensionProvider);
    pasteListener = be.pasteController.stream.listen((pasteImage) {
      if (focusNode.hasFocus && !isPasting) {
        handlePaste(pasteImage: pasteImage);
      }
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
          var sourceUrl = await db.uploadAttachment(fileBytes: pasteImage);
          controller.text = sourceUrl;
          widget.onChanged?.call();
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
        db.insertTextAtSelection(controller, clipboardText);
        widget.onChanged?.call();
      }
    }
    setState(() {
      isPasting = false;
    });
  }

  @override
  void dispose() {
    pasteListener?.cancel();
    saveTimer?.cancel();
    super.dispose();
  }

  void onPressedPreview(String url) {
    Uri uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    if (m != null) {
      return SourcePreview(
        metadata: m,
        onPressed: () => onPressedPreview(m.url),
        onClear: widget.onClearSource,
      );
    }
    return TextField(
        focusNode: focusNode,
        textInputAction: TextInputAction.next,
        contextMenuBuilder: (context, editableTextState) {
          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            controller.selection = TextSelection(
                baseOffset: 0, extentOffset: controller.value.text.length);
          });
          Uri? uri = Uri.tryParse(controller.text);
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              if (controller.text.isNotEmpty && uri != null)
                ContextMenuButtonItem(
                  onPressed: () =>
                      launchUrl(uri, mode: LaunchMode.externalApplication),
                  label: 'Open Source',
                ),
              ...editableTextState.contextMenuButtonItems,
            ],
          );
        },
        readOnly: widget.readOnly,
        style: Theme.of(context).textTheme.bodySmall,
        controller: controller,
        onChanged: (text) => widget.onChanged?.call(),
        textDirection: widget.textDirection,
        decoration: const InputDecoration(
          isDense: true,
          hintText: "Source",
          border: InputBorder.none,
        ));
  }
}
