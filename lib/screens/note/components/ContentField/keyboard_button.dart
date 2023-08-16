import 'package:flutter/material.dart';

class KeyboardButton extends StatelessWidget {
  const KeyboardButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.disabled = false,
  }) : super(key: key);

  final dynamic icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 5, top: 3, bottom: 3),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 1.0, // Initial elevation
          backgroundColor: Theme.of(context).colorScheme.background,
          foregroundColor: Theme.of(context).colorScheme.onBackground,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
