import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';

import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';

class NoteScreenNavigator extends StatelessWidget {
  const NoteScreenNavigator({
    Key? key,
    required this.db,
  }) : super(key: key);

  final RealmDB db;

  @override
  Widget build(BuildContext context) {
    db.navigatorKey = GlobalKey<NavigatorState>();
    var history = db.noteHistory.entries.toList();

    return Navigator(
      key: db.navigatorKey,
      onGenerateRoute: (route) => PageRouteBuilder(
        settings: route,
        pageBuilder: (context, _, __) {
          if (history.isEmpty) return Container();
          return NoteScreen(
            key: history.first.value,
            note: history.first.key,
            db: db,
          );
        },
      ),
    );
  }
}
