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
  late List<String> items = [
    'hello',
    'world',
    'how',
    'are',
    'you',
    'asdf',
    'asdf',
    'asdf',
    'df',
    'adf',
    'd',
    'f',
    'gg'
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return SearchResultCard(title: 'title', content: items[index]);
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
