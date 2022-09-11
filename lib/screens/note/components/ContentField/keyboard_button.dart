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
    return IconButton(
      onPressed: (disabled) ? null : () => onPressed?.call(),
      icon: icon is String
          ? Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: (disabled) ? Colors.grey : null,
              ),
            )
          : Icon(icon, size: 20, color: (disabled) ? Colors.grey : null),
      tooltip: tooltip,
    );
  }
}
