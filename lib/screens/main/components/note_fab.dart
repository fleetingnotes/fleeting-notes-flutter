import 'package:flutter/material.dart';

class NoteFAB extends StatelessWidget {
  const NoteFAB({
    super.key,
    required this.onPressed,
    this.isElevated = true,
  });

  final VoidCallback onPressed;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: isElevated ? null : 0,
      child: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
