import 'package:flutter/material.dart';

class NoteFAB extends StatelessWidget {
  const NoteFAB({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
