import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id, timestamp;
  String title, content;
  final bool hasAttachment;
  bool isDeleted;
  static const String invalidChars = r'\[\]\#\*';
  static const String linkRegex = "\\[\\[([^$invalidChars]+?)\\]\\]";

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isDeleted = false,
    this.hasAttachment = false,
  });

  static Note empty({String title = '', String content = ''}) {
    Uuid uuid = const Uuid();
    String dateStr = DateTime.now().toIso8601String();
    return Note(
      id: uuid.v1(),
      title: title,
      content: content,
      timestamp: dateStr,
      isDeleted: false,
      hasAttachment: false,
    );
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
