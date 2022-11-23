import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note_editor.dart';

class NoteScreenNavigator extends ConsumerWidget {
  NoteScreenNavigator({
    Key? key,
    this.hasInitNote = false,
  }) : super(key: key);

  final bool hasInitNote;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
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
            isShared: hasInitNote,
          );
        },
      ),
    );
  }
}
