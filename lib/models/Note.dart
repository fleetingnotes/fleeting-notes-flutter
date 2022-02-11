import 'package:flutter/material.dart';
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

  String getDateTime() {
    DateTime.now();
    return 'time';
  }
}
