import 'package:flutter/material.dart';
import '../../models/Note.dart';

import '../../constants.dart';

class NoteScreen extends StatelessWidget {
  const NoteScreen({
    Key? key,
    required this.note,
  }) : super(key: key);

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(),
              Divider(thickness: 1),
            ],
          ),
        ),
      ),
    );
  }
}
