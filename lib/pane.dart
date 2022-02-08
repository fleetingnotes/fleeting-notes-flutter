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
  late List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Text('query:' + widget.query)),
      color: Colors.green,
    );
  }
}
