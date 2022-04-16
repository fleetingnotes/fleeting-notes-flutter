import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/my_app.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/my_app_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox('settings');
  runApp(const MyApp());
}
