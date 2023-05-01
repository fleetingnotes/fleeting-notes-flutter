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

  void appendToDoc(String text) {
    String md = serializeDocumentToMarkdown(contentDoc);
    md += text;
    contentDoc = deserializeMarkdownToDocument(md);
  }

  void updateFields(Note n) {
    titleController.text = n.title;
    sourceController.text = n.source;
    contentDoc = deserializeMarkdownToDocument(n.content);
  }
}
