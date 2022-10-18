import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:fleeting_notes_flutter/my_app_mobile.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/my_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  GoRouter.setUrlPathStrategy(UrlPathStrategy.path);
  await SentryFlutter.init(
    (options) {
      options.dsn = kDebugMode
          ? ''
          : 'https://49ad5c0ab4f142e7a2a10926a1579125@o1423992.ingest.sentry.io/6771762';
    },
    // Init your App.
    appRunner: () async {
      await initApp();
      runApp(const MyApp());
    },
  );
}
