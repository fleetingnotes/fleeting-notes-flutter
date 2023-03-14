import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receive_intent/receive_intent.dart' as ri;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'my_app.dart' as base_app;

class MyApp extends base_app.MyApp {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<base_app.MyApp> createState() => _MyAppState();
}

class ParsedHighlight {
  String content = '';
  String source = '';

  ParsedHighlight(this.content, this.source);
}

class _MyAppState extends base_app.MyAppState<MyApp> {
  StreamSubscription? noteChangeStream;
  StreamSubscription? homeWidgetSub;
  StreamSubscription? receiveShareSub;
  StreamSubscription? androidIntentSub;

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

  Future<Note> getNoteFromWidgetUri(Uri uri) async {
    final db = ref.read(dbProvider);
    var noteId = uri.queryParameters['id'];
    if (noteId != null) {
      try {
        Note? note = await db.getNote(noteId);
        return note ?? Note.empty();
      } catch (e) {
        debugPrint(e.toString());
        return Note.empty();
      }
    }
    return Note.empty();
  }

  void homeWidgetRefresh(event) async {
    final db = ref.read(dbProvider);
    debugPrint("homeWidgetRefresh");
    var q = SearchQuery(query: '', sortBy: SortOptions.createdDESC, limit: 25);
    var notes = await db.getSearchNotes(q);
    await HomeWidget.saveWidgetData('notes', jsonEncode(notes));
    await HomeWidget.updateWidget(
        name: 'WidgetProvider', iOSName: 'NoteListWidgetExtension');
  }

  @override
  void refreshApp(user) {
    super.refreshApp(user);
    initHomeWidget();
  }

  void initHomeWidget() {
    final db = ref.read(dbProvider);
    homeWidgetRefresh(null);
    noteChangeStream?.cancel();
    db.listenNoteChange(homeWidgetRefresh).then((stream) {
      noteChangeStream = stream;
    });
  }

  @override
  void initState() {
    super.initState();
    initHomeWidget();
    void goToNote(Note note) {
      final noteHistory = ref.read(noteHistoryProvider.notifier);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        noteHistory.addNote(context, note, router: router);
      });
    }

    Note getNoteFromShareText({String title = '', String body = ''}) {
      var ph = findAndroidHighlight(body);
      if (ph != null) {
        return Note.empty(title: title, content: ph.content, source: ph.source);
      }
      bool _validURL = Uri.tryParse(body)?.hasAbsolutePath ?? false;
      if (_validURL) {
        return Note.empty(title: title, source: body);
      } else {
        return Note.empty(title: title, content: body);
      }
    }

    void handleAndroidIntent(ri.Intent? intent) {
      if (intent == null ||
          intent.isNull ||
          intent.action != 'android.intent.action.EDIT') return;
      // Validate receivedIntent and warn the user, if it is not correct,
      // but keep in mind it could be `null` or "empty"(`receivedIntent.isNull`).
      String title = (intent.extra?['name'] ?? '').toString();
      String body = (intent.extra?['articleBody'] ?? '').toString();
      var note = getNoteFromShareText(title: title, body: body);
      goToNote(note);
    }

    if (Platform.isAndroid) {
      ri.ReceiveIntent.getInitialIntent().then(handleAndroidIntent);
      androidIntentSub = ri.ReceiveIntent.receivedIntentStream
          .listen(handleAndroidIntent, onError: (err) {
        // ignore: avoid_print
        print(err);
      });
    }
    if (Platform.isIOS || Platform.isAndroid) {
      // For sharing or opening urls/text coming from outside the app while the app is in the memory
      receiveShareSub =
          ReceiveSharingIntent.getTextStream().listen((String sharedText) {
        var note = getNoteFromShareText(body: sharedText);
        goToNote(note);
      }, onError: (err) {
        // ignore: avoid_print
        print("getLinkStream error: $err");
      });

      // For sharing or opening urls/text coming from outside the app while the app is closed
      ReceiveSharingIntent.getInitialText().then((String? sharedText) {
        if (sharedText != null) {
          var note = getNoteFromShareText(body: sharedText);
          goToNote(note);
        }
      });

      // When app is started from widget
      HomeWidget.setAppGroupId('group.com.fleetingnotes');
      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri != null) {
          getNoteFromWidgetUri(uri).then((note) {
            goToNote(note);
          });
        }
      });

      homeWidgetSub = HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) {
          getNoteFromWidgetUri(uri).then((note) {
            goToNote(note);
          });
        }
      }, onError: (err) {
        // ignore: avoid_print
        print(err);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    noteChangeStream?.cancel();
    homeWidgetSub?.cancel();
    receiveShareSub?.cancel();
    androidIntentSub?.cancel();
  }
}
