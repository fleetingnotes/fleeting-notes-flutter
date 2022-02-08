import 'package:flutter/material.dart';

class Pane extends StatefulWidget {
  const Pane({Key? key, required this.query}) : super(key: key);

  final String query;

  @override
  State<Pane> createState() => _PaneState();
}

class _PaneState extends State<Pane> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Text('currPaneIndex is $widget.currPaneIndex')),
      color: Colors.green,
    );
  }
}
