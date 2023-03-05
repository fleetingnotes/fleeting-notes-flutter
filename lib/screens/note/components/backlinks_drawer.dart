import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/Note.dart';

class BacklinksDrawer extends ConsumerStatefulWidget {
  const BacklinksDrawer({
    Key? key,
    this.searchQuery,
    this.backlinks = const [],
    this.closeDrawer,
    this.width,
  }) : super(key: key);

  final SearchQuery? searchQuery;
  final List<Note> backlinks;
  final VoidCallback? closeDrawer;
  final double? width;

  @override
  ConsumerState<BacklinksDrawer> createState() => _BacklinksDrawerState();
}

class _BacklinksDrawerState extends ConsumerState<BacklinksDrawer> {
  void onNoteTap(context, note) {
    var nh = ref.read(noteHistoryProvider.notifier);
    widget.closeDrawer?.call();
    nh.addNote(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                      'Backlinks',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                    IconButton(
                      onPressed: widget.closeDrawer,
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: NoteGrid(
                  crossAxisCount: 1,
                  maxLines: 2,
                  searchQuery: widget.searchQuery,
                  notes: widget.backlinks,
                  onTap: onNoteTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
