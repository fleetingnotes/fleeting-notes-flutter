// ignore_for_file: file_names
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  @HiveField(5)
  final bool hasAttachment;
  @HiveField(6)
  bool isDeleted;
  static const String invalidChars = r'\[\]\#\*';
  static const String linkRegex = "\\[\\[([^$invalidChars]+?)\\]\\]";

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.source = '',
    this.isDeleted = false,
    this.hasAttachment = false,
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
      hasAttachment: false,
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
      hasAttachment: note.hasAttachment,
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
}
