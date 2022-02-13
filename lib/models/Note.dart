import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// initializeDateFormatting('fr_FR', null).then((_) => runMyCode());

class Note {
  final String id, title, content;
  final bool hasAttachment;
  Note({
    required this.id,
    required this.title,
    required this.content,
    this.hasAttachment = false,
  });

  DateTime getDateTime() {
    try {
      var date = DateTime(
        int.parse(id.substring(0, 4)),
        int.parse(id.substring(4, 6)),
        int.parse(id.substring(6, 8)),
        int.parse(id.substring(8, 10)),
        int.parse(id.substring(10, 12)),
        int.parse(id.substring(12, 14)),
      );
      return date;
    } catch (e) {
      return DateTime.now();
    }
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
