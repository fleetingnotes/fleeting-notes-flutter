import 'package:flutter/material.dart';

class NoteFAB extends StatelessWidget {
  const NoteFAB({
    super.key,
    required this.onPressed,
    this.onLongPress,
  });

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: FloatingActionButton(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: onPressed,
      ),
    );
  }
}
