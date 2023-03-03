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
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add),
      tooltip: 'New note',
      onPressed: onPressed,
    );
  }
}
