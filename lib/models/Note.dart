// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import "package:yaml/yaml.dart";

part 'Note.g.dart';

@HiveType(typeId: 1)
class Note {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String timestamp;
  @HiveField(2)
  String title;
  @HiveField(3)
  String content;
  @HiveField(4)
  String source;
  @HiveField(6)
  bool isDeleted;
  @HiveField(7, defaultValue: false)
  bool isShareable;
  final String partition;
  static const String invalidChars = r'\[\]\#\*\:\/\\\^';
  static const String linkRegex = "\\[\\[([^$invalidChars]+?)\\]\\]";
  static const String defaultNoteTemplate = r'''
---
id: "${id}"
title: "${title}"
source: "${source}"
created_time: "${created_time}"
---
${content}''';

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isShareable = false,
    this.partition = '',
    this.source = '',
    this.isDeleted = false,
  });

  static Note empty(
      {String title = '', String content = '', String source = ''}) {
    Uuid uuid = const Uuid();
    String dateStr = DateTime.now().toIso8601String();
    return Note(
      id: uuid.v1(),
      title: title,
      content: content,
      source: source,
      timestamp: dateStr,
      isDeleted: false,
    );
  }

  toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'source': source,
      'timestamp': timestamp,
    };
  }

  static Note fromMap(dynamic note) {
    Map noteMap = Map.from(note);
    return Note(
      id: noteMap["_id"].toString(),
      title: noteMap["title"].toString(),
      content: noteMap["content"].toString(),
      source: noteMap["source"].toString(),
      timestamp: noteMap["timestamp"].toString(),
    );
  }

  static Note encodeNote(Note note) {
    return Note(
      id: jsonEncode(note.id),
      title: jsonEncode(note.title),
      content: jsonEncode(note.content),
      source: jsonEncode(note.source),
      timestamp: jsonEncode(note.timestamp),
      isDeleted: note.isDeleted,
    );
  }

  static newNoteFromFile(String title, String content) {
    // parse frontmatter of content
    var frontmatter = {};
    var match = RegExp(r'^---\n([\s\S]*?)\n---\n').firstMatch(content);
    if (match != null) {
      try {
        frontmatter = loadYaml(match.group(1) ?? '');
        content = content.replaceFirst(match.group(0) ?? '', '');
      } catch (e) {
        debugPrint('Error parsing frontmatter: $e');
      }
    }

    return Note.empty(
      title: (frontmatter.containsKey('title'))
          ? frontmatter['title'].toString()
          : title,
      content: content,
      source: (frontmatter.containsKey('source'))
          ? frontmatter['source'].toString()
          : '',
    );
  }

  bool isEmpty() {
    return title == '' && content == '' && source == '';
  }

  DateTime getDateTime() {
    return DateTime.parse(timestamp);
  }

  String getShortDateTimeStr() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDateTime = getDateTime();
    final noteDate =
        DateTime(noteDateTime.year, noteDateTime.month, noteDateTime.day);

    if (noteDate == today) {
      return DateFormat('jm').format(noteDateTime);
    } else if (today.year == noteDate.year) {
      return DateFormat('MMM. d').format(noteDateTime);
    } else {
      return DateFormat('yyyy-M-d').format(noteDateTime);
    }
  }

  String getDateTimeStr() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDateTime = getDateTime();
    final noteDate =
        DateTime(noteDateTime.year, noteDateTime.month, noteDateTime.day);

    if (noteDate == today) {
      return 'Today at ${DateFormat('jm').format(noteDateTime)}';
    }
    return DateFormat('MMMM d, y').format(noteDateTime);
  }

  String getMarkdownFilename() {
    return (title.isEmpty) ? "$id.md" : "$title.md";
  }

  String getMarkdownContent({String? template}) {
    bool matchInMetadata(Match m, String template) {
      RegExpMatch? metadataMatch =
          RegExp(r'^---\n([\s\S]*?)\n---\n').firstMatch(template);
      if (metadataMatch == null) return false;
      return m.start > metadataMatch.start && m.end < metadataMatch.end;
    }

    template = (template == null) ? defaultNoteTemplate : template;
    var r = RegExp(r"\$\{(.*)\}", multiLine: true);
    var mdContent = template.replaceAllMapped(r, (m) {
      var variable = m.group(1);
      switch (variable) {
        case 'id':
          if (matchInMetadata(m, template ?? '')) {
            return id.replaceAll('"', r'\"');
          }
          return id;
        case 'title':
          if (matchInMetadata(m, template ?? '')) {
            return title.replaceAll('"', r'\"');
          }
          return title;
        case 'source':
          if (matchInMetadata(m, template ?? '')) {
            return source.replaceAll('"', r'\"');
          }
          return source;
        case 'created_time':
          if (matchInMetadata(m, template ?? '')) {
            return timestamp.replaceAll('"', r'\"');
          }
          return timestamp;
        case 'content':
          if (matchInMetadata(m, template ?? '')) {
            return content.replaceAll('"', r'\"');
          }
          return content;
        default:
          return m.group(0) ?? '';
      }
    });
    return mdContent;
  }
}
