import 'package:fleeting_notes_flutter/screens/note/note_list.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return const NoteList();
  }
}
