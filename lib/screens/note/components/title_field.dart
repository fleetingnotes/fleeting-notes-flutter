import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  const TitleField({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      controller: controller,
      decoration: const InputDecoration(
        hintText: "Title",
        border: InputBorder.none,
      ),
      onChanged: (text) {
        if (onChanged != null) {
          onChanged!();
        }
      },
    );
  }
}
