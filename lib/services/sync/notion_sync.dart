import 'dart:io';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/models/syncterface.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:flutter/material.dart';

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
import 'package:notion_api/notion/general/rich_text.dart' as notion_rich_text;
import 'package:notion_api/notion/general/types/notion_types.dart';
import 'package:notion_api/notion/objects/database.dart';
import 'package:notion_api/notion/objects/pages.dart' as notion_pages;
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
  bool get enabled => settings.get('local-sync-enabled', defaultValue: false);
  String get notionToken => settings.get('notion-token-dir', defaultValue: '');
  String? get notionDatabaseId => settings.get('notion-sync-template');
  NotionClient notion =
      NotionClient(token: 'secret_uLhLrE77KJJYLjfgSfwvPJ22CFfTqAquOUotnnEkRxb');

  @override
  bool canSync() {
    return enabled && notionToken.isNotEmpty && notionDatabaseId != null;
  }

  @override
  void pushNotes(List<Note> notes) {
    print('NotionSync: pushNotes');
    // var idToPath = getNoteIdToPathMapping();
    // for (var n in notes) {
    //   String mdContent = n.getMarkdownContent(template: template);
    //   File f;
    //   if (idToPath.containsKey(n.id)) {
    //     f = File(idToPath[n.id] as String);
    //   } else {
    //     String fileName = n.getMarkdownFilename();
    //     f = File(p.join(syncDir, fileName));
    //   }
    //   f.writeAsString(mdContent);
    // }

    // Create a page instance
    notion_pages.Page page = notion_pages.Page(
      parent: const Parent.database(id: '95467b238a14477d89ba3faefa7e6a52'),
      title: notion_rich_text.Text('NotionClient (v1): Page test'),
    );

  // Send the instance to Notion.
    // var response = notion.pages.create(page);
    var response = notion.databases.fetch('95467b238a14477d89ba3faefa7e6a52');
    print('NotionSync: pushNotes: response: $response');
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
