import 'package:fleeting_notes_flutter/screens/note/components/super_editor_utils.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';
import '../models/Note.dart';

// utilities to help do things with notes
class EditorData {
  ProviderRef ref;
  EditorData(this.ref);
  TextEditingController titleController = TextEditingController();
  MutableDocument contentDoc = MutableDocument();
  TextEditingController sourceController = TextEditingController();
  CommonEditorOperations? docOps;

  void appendToDoc(String text) {
    String md = serializeDocToMd(contentDoc);
    md += text;
    contentDoc = deserializeMdToDoc(md);
  }

  void updateFields(Note n) {
    titleController.text = n.title;
    sourceController.text = n.source;
    contentDoc = deserializeMdToDoc(n.content);
  }

  MutableDocument deserializeMdToDoc(String md) {
    return deserializeMarkdownToDocument(md,
        customElementToNodeConverters: [TaskElementToNode()]);
  }

  String serializeDocToMd(MutableDocument doc) {
    return serializeDocumentToMarkdown(doc,
        customNodeSerializers: [TaskNodeSerializer()]);
  }
}
