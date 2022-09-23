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
  final String _id;
  @HiveField(1)
  final String _createdTime;
  @HiveField(2)
  String _title;
  @HiveField(3)
  String _content;
  @HiveField(4)
  String _source;
  @HiveField(6)
  bool _isDeleted;
  @HiveField(7, defaultValue: false)
  bool _isShareable;
  @HiveField(8)
  String _lastModifiedTime;
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
    required String id,
    required String createdTime,
    String? lastModifiedTime,
    String title = '',
    String content = '',
    String source = '',
    bool isShareable = false,
    bool isDeleted = false,
    this.partition = '',
  })  : _id = id,
        _title = title,
        _content = content,
        _source = source,
        _createdTime = createdTime,
        _lastModifiedTime = lastModifiedTime ?? createdTime,
        _isDeleted = isDeleted,
        _isShareable = isShareable;

  // getters
  String get id => _id;
  String get title => _title;
  String get content => _content;
  String get source => _source;
  DateTime get createdTime => DateTime.parse(_createdTime);
  DateTime get lastModifiedTime => DateTime.parse(_lastModifiedTime);
  String get shortCreated => getShortDateTimeStr(createdTime);
  String get shortLastModified => getShortDateTimeStr(lastModifiedTime);
  String get longCreated => getLongDateTimeStr(createdTime);
  String get longLastModified => getLongDateTimeStr(lastModifiedTime);
  bool get isShareable => _isShareable;
  bool get isDeleted => _isDeleted;

  // setters
  set title(String val) {
    _title = val;
    _lastModifiedTime = DateTime.now().toIso8601String();
  }

  set content(String val) {
    _content = val;
    _lastModifiedTime = DateTime.now().toIso8601String();
  }

  set source(String val) {
    _source = val;
    _lastModifiedTime = DateTime.now().toIso8601String();
  }

  set isShareable(bool val) {
    _isShareable = val;
    _lastModifiedTime = DateTime.now().toIso8601String();
  }

  set isDeleted(bool val) {
    _isDeleted = val;
    _lastModifiedTime = DateTime.now().toIso8601String();
  }

  static Note empty(
      {String title = '', String content = '', String source = ''}) {
    Uuid uuid = const Uuid();
    String dateStr = DateTime.now().toIso8601String();
    return Note(
      id: uuid.v1(),
      title: title,
      content: content,
      source: source,
      createdTime: dateStr,
      isDeleted: false,
    );
  }

  toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'source': source,
      'timestamp': createdTime.toIso8601String(),
    };
  }

  static Note fromMap(dynamic note) {
    Map noteMap = Map.from(note);
    return Note(
      id: noteMap["_id"].toString(),
      title: noteMap["title"].toString(),
      content: noteMap["content"].toString(),
      source: noteMap["source"].toString(),
      createdTime: noteMap["timestamp"].toString(),
    );
  }

  static Note encodeNote(Note note) {
    return Note(
      id: note.id,
      title: jsonEncode(note.title),
      content: jsonEncode(note.content),
      source: jsonEncode(note.source),
      createdTime: note.createdTime.toIso8601String(),
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

  String getShortDateTimeStr(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (noteDate == today) {
      return DateFormat('jm').format(dateTime);
    } else if (today.year == noteDate.year) {
      return DateFormat('MMM. d').format(dateTime);
    } else {
      return DateFormat('yyyy-M-d').format(dateTime);
    }
  }

  String getLongDateTimeStr(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (noteDate == today) {
      return 'Today at ${DateFormat('jm').format(dateTime)}';
    }
    return DateFormat('MMMM d, y').format(dateTime);
  }

  String getMarkdownFilename() {
    return (title.isEmpty) ? "$id.md" : "$title.md";
  }

  String getMarkdownContent({String? template}) {
    template = (template == null) ? defaultNoteTemplate : template;
    var r = RegExp(r"\$\{(.*)\}", multiLine: true);
    var mdContent = template.replaceAllMapped(r, (m) {
      var variable = m.group(1);
      switch (variable) {
        case 'id':
          return id;
        case 'title':
          return title;
        case 'source':
          return source;
        case 'created_time':
          return createdTime.toIso8601String();
        case 'content':
          return content;
        default:
          return m.group(0) ?? '';
      }
    });
    return mdContent;
  }
}
