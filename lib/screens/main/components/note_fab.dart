import 'package:flutter/material.dart';

class NoteFAB extends StatelessWidget {
  const NoteFAB({
    super.key,
    required this.onPressed,
    required this.isElevated,
  });

  final VoidCallback onPressed;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: onPressed,
      elevation: (isElevated) ? null : 0,
    );
  }
}
