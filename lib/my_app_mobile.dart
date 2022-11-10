import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'my_app.dart' as base_app;

class MyApp extends base_app.MyApp {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<base_app.MyApp> createState() => _MyAppState();
}

class ParsedHighlight {
  String content = '';
  String source = '';

  ParsedHighlight(this.content, this.source);
}

class _MyAppState extends base_app.MyAppState<MyApp> {
  ParsedHighlight? findAndroidHighlight(String sharedText) {
    if (!Platform.isAndroid) return null;
    var r = RegExp(r'^"(.+)"[\n\r\s]+(.+)', multiLine: true);
    var m = r.firstMatch(sharedText);
    if (m != null) {
      String content = m.group(1) ?? '';
      String source = m.group(2)?.trim() ?? '';
      bool validSource = Uri.tryParse(source)?.hasAbsolutePath ?? false;
      if (validSource) {
        return ParsedHighlight(content, source);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    Note getNoteFromShareText(String sharedText) {
      var ph = findAndroidHighlight(sharedText);
      if (ph != null) {
        return Note.empty(content: ph.content, source: ph.source);
      }
      bool _validURL = Uri.tryParse(sharedText)?.hasAbsolutePath ?? false;
      if (_validURL) {
        return Note.empty(source: sharedText);
      } else {
        return Note.empty(content: sharedText);
      }
    }

    if (Platform.isIOS || Platform.isAndroid) {
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      ReceiveSharingIntent.getTextStream().listen((String sharedText) {
        db.navigateToNote(getNoteFromShareText(sharedText), isShared: true);
      }, onError: (err) {
        // ignore: avoid_print
        print("getLinkStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then((String? sharedText) {
        if (sharedText != null) {
          db.popAllRoutes();
          db.navigateToNote(getNoteFromShareText(sharedText), isShared: true);
        }
      });
    }
  }
}
