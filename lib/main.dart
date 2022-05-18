import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fleeting_notes_flutter/my_app_mobile.dart'
    if (dart.library.js) 'package:fleeting_notes_flutter/my_app.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await openHiveBox('settings');
}

void main() async {
  if (kIsWeb) {
    await initApp();
    runApp(const MyApp());
  } else {
    runZonedGuarded<Future<void>>(() async {
      await initApp();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      runApp(const MyApp());
    },
        (error, stack) =>
            FirebaseCrashlytics.instance.recordError(error, stack));
  }
}
