import 'dart:html';

import 'package:flutter/material.dart';

class Pane extends StatefulWidget {
  const Pane({Key? key, required this.query, required this.visible})
      : super(key: key);

  final String query;
  final bool visible;

  @override
  State<Pane> createState() => _PaneState();
}

class _PaneState extends State<Pane> {
  final ScrollController scrollController = ScrollController();
  late List<Map<String, String>> notes;

  _PaneState() {
    // function to get notes from realm here
    notes = [
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
      {"id": "0", "title": "hello", "content": "world"},
    ];
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
              title: "First",
              content: "Note",
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
  const NoteCard({Key? key, required this.title, required this.content})
      : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: const [
          TextField(
            decoration: InputDecoration(
              hintText: "Title",
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: "Note",
            ),
          ),
        ],
      ),
    );
  }
}
