import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';

import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';

class NoteScreenNavigator extends StatelessWidget {
  NoteScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final Database db;

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  Widget build(BuildContext context) {
    db.navigatorKey = GlobalKey<NavigatorState>();
    db.routeObserver = routeObserver;
    var history = db.noteHistory.entries.toList();

    return Navigator(
      key: db.navigatorKey,
      observers: [routeObserver],
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) {
          if (history.isEmpty) return Container();
          return NoteEditor(
            key: history.first.value,
            note: history.first.key,
            db: db,
          );
        },
      ),
    );
  }
}
