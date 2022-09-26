import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:notion_api/base_client.dart';
import 'package:notion_api/notion.dart';
import 'package:notion_api/notion/blocks/block.dart';
import 'package:notion_api/notion/blocks/bulleted_list_item.dart';
import 'package:notion_api/notion/blocks/heading.dart';
import 'package:notion_api/notion/blocks/numbered_list_item.dart';
import 'package:notion_api/notion/blocks/paragraph.dart';
import 'package:notion_api/notion/blocks/todo.dart';
import 'package:notion_api/notion/blocks/toggle.dart';
import 'package:notion_api/notion/general/base_fields.dart';
import 'package:notion_api/notion/general/lists/children.dart';
import 'package:notion_api/notion/general/lists/pagination.dart';
import 'package:notion_api/notion/general/lists/properties.dart';
import 'package:notion_api/notion/general/property.dart';
import 'package:notion_api/notion/general/rich_text.dart' as n_text;
import 'package:notion_api/notion/general/types/notion_types.dart';
import 'package:notion_api/notion/objects/database.dart';
import 'package:notion_api/notion/objects/pages.dart' as n_pages;
import 'package:notion_api/notion/objects/parent.dart';
import 'package:notion_api/notion_blocks.dart';
import 'package:notion_api/notion_databases.dart';
import 'package:notion_api/notion_pages.dart';
import 'package:notion_api/responses/notion_response.dart';
import 'package:notion_api/statics.dart';
import 'package:notion_api/utils/utils.dart';

import 'package:http/http.dart' as http;

class NotionSync extends SyncTerface {
  NotionSync({
    required this.settings,
  }) : super();
  final Settings settings;

  bool get enabled => settings.get('notion-sync-enabled', defaultValue: false);
  String get notionToken => settings.get('notion-token', defaultValue: '');
  String get notionDatabaseId =>
      settings.get('notion-database-id', defaultValue: '');
  //initialize notionclient with token
  late NotionClient notion = NotionClient(token: notionToken);

  @override
  bool canSync() {
    return enabled && notionToken.isNotEmpty && notionDatabaseId.isNotEmpty;
  }

  @override
  void pushNotes(List<Note> notes) async {
    for (var note in notes) {
      // get all notes 
      var findPage = await notion.pages.fetch(note.id);
      debugPrint('pushNotes note $note');
      n_pages.Page page = n_pages.Page(
        parent: Parent.database(id: notionDatabaseId),
        title: n_text.Text(note.title),
        id: note.id,
      );
      var newPage = await notion.pages.create(page);
      // var response = notion.databases.fetch('95467b238a14477d89ba3faefa7e6a52');
      debugPrint('response $newPage');
      // Send the instance to Notion API

      // Get the new id generated for the created page
      String newPageId = newPage.page!.id;

      // Create the instance of the content of the page
      Children fullContent = Children.withBlocks([
        Paragraph(texts: [
          n_text.Text(note.content),
        ])
      ]);

      // Append the content to the page
      var res = await notion.blocks.append(
        to: newPageId,
        children: fullContent,
      );

      notion.pages.update(
        newPageId,
        properties: Properties(map: {
          'Source': RichTextProp(content: [
            n_text.Text(note.source),
          ]),
          'Created': RichTextProp(content: [
            n_text.Text(note.timestamp),
          ]),
        }),
      );
    }
  }

  @override
  void deleteNotes(List<Note> notes) {
    // var idToPath = getNoteIdToPathMapping();
    // for (var n in notes) {
    //   if (idToPath.containsKey(n.id)) {
    //     var f = File(idToPath[n.id] as String);
    //     f.delete();
    //   }
    // }
  }
}
