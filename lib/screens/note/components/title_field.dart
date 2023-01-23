import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  const TitleField({
    Key? key,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      controller: controller,
      decoration: const InputDecoration(
        hintText: "Title",
        border: InputBorder.none,
      ),
      onChanged: (text) {
        onChanged?.call();
      },
      autofocus: autofocus,
    );
  }
}
