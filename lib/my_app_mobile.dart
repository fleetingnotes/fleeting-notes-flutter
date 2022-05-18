import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'my_app.dart' as base_app;

class MyApp extends base_app.MyApp {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<base_app.MyApp> createState() => _MyAppState();
}

class _MyAppState extends base_app.MyAppState<MyApp> {
  @override
  void initState() {
    super.initState();
    Note getNoteFromShareText(String sharedText) {
      try {
        bool _validURL = Uri.parse(sharedText).isAbsolute;
        if (_validURL) {
          return Note.empty(source: sharedText);
        } else {
          return Note.empty(content: sharedText);
        }
      } on FormatException {
        return Note.empty(content: sharedText);
      }
    }

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getTextStream().listen((String sharedText) {
      db.navigateToNote(getNoteFromShareText(sharedText), isShared: true);
      db.firebase.analytics.logEvent(name: 'receive_share');
    }, onError: (err) {
      // ignore: avoid_print
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? sharedText) {
      if (sharedText != null) {
        setState(() {
          initNote = getNoteFromShareText(sharedText);
        });
        db.firebase.analytics.logEvent(name: 'receive_share');
      }
    });
  }
}
