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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      controller: controller,
      decoration: const InputDecoration(
        hintText: "Title of the idea",
        border: InputBorder.none,
      ),
      onChanged: (text) {
        if (onChanged != null) {
          onChanged!();
        }
      },
      autofocus: autofocus,
    );
  }
}
