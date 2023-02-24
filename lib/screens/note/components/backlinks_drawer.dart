import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:fleeting_notes_flutter/screens/search/search_screen.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/Note.dart';

class BacklinksDrawer extends ConsumerStatefulWidget {
  const BacklinksDrawer({
    Key? key,
    this.title = '',
    this.closeDrawer,
    this.width,
  }) : super(key: key);

  final String title;
  final VoidCallback? closeDrawer;
  final double? width;

  @override
  ConsumerState<BacklinksDrawer> createState() => _BacklinksDrawerState();
}

class _BacklinksDrawerState extends ConsumerState<BacklinksDrawer> {
  SearchQuery searchQuery = SearchQuery();
  List<Note> backlinks = [];
  @override
  void initState() {
    final db = ref.read(dbProvider);
    searchQuery.query = "[[${widget.title}]]";
    db.getSearchNotes(searchQuery).then((notes) {
      setState(() {
        backlinks = notes;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Drawer(
        child: Column(
          children: [
            SafeArea(
              child: Padding(
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
            ),
            const Divider(),
            Expanded(
              child: NoteGrid(
                childAspectRatio: 3,
                searchQuery: SearchQuery(query: "[[${widget.title}]]"),
                notes: backlinks,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
