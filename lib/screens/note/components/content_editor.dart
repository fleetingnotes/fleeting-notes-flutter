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
      composer: DocumentComposer(),
      autofocus: widget.autofocus,
      // stylesheet: Stylesheet(
      //   rules: [],
      //   inlineTextStyler: (a, t) {
      //     return t;
      //   },
      //   documentPadding: EdgeInsets.zero,
      // ),
    );
  }
}
