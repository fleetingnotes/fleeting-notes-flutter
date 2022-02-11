import 'package:flutter/material.dart';

class Pane extends StatefulWidget {
  const Pane(
      {Key? key,
      required this.query,
      required this.visible,
      required this.getNotes})
      : super(key: key);

  final String query;
  final bool visible;
  final Function getNotes;

  @override
  State<Pane> createState() => _PaneState();
}

class _PaneState extends State<Pane> {
  final ScrollController scrollController = ScrollController();
  late List<Map<String, String>> notes = [];

  Future<void> loadNotes() async {
    var tempNotes = await widget.getNotes();
    setState(() {
      notes = tempNotes;
    });
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        itemCount: notes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const NoteCard(
              id: "0",
              title: "First. Good Stuff",
              content: "Note Test",
            );
          }
          index -= 1;
          String title = notes[index]["title"].toString();
          String content = notes[index]["content"].toString();
          return SearchResultCard(title: title, content: content);
        },
        controller: scrollController,
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({Key? key, required this.title, required this.content})
      : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard(
      {Key? key, required this.id, required this.title, required this.content})
      : super(key: key);

  final String id;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  style: const TextStyle(fontSize: 16),
                  controller: TextEditingController(text: title),
                  decoration: const InputDecoration(
                    hintText: "Title",
                    border: InputBorder.none,
                  ),
                ),
                TextField(
                  autofocus: true,
                  controller: TextEditingController(text: content),
                  minLines: 5,
                  maxLines: 10,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Note",
                    border: InputBorder.none,
                  ),
                ),
                Text(
                  id,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w100),
                  // textAlign: TextAlign.left,
                ),
              ],
            )));
  }
}
