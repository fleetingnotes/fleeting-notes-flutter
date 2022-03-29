import 'package:fleeting_notes_flutter/screens/auth/auth_screen.dart';
import 'package:fleeting_notes_flutter/screens/main/state/note_stack_model.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';

import 'package:fleeting_notes_flutter/screens/note/components/note_editor.dart';
import 'package:provider/provider.dart';

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
