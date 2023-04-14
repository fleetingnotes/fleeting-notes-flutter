import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fleeting_notes_flutter/my_app_mobile.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/my_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<Box> openHiveBox(String boxName) async {
  if (!kIsWeb && !Hive.isBoxOpen(boxName)) {
    Hive.init((await getApplicationDocumentsDirectory()).path);
  }
  return await Hive.openBox(boxName);
}

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Supabase.initialize(
    url: "https://yixcweyqwkqyvebpmdvr.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeGN3ZXlxd2txeXZlYnBtZHZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQ4MDMyMTgsImV4cCI6MTk4MDM3OTIxOH0.awfZKRuaLOPzniEJ2CIth8NWPYnelLfsWrMWH2Bz3w8",
  );
  await openHiveBox('settings');
}

void main() async {
  usePathUrlStrategy();
  await initApp();
  runApp(const ProviderScope(child: MyApp()));
}
