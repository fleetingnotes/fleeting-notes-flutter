import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  const TitleField(
      {Key? key,
      required this.controller,
      this.onChanged,
      this.autofocus = false,
      this.textDirection = TextDirection.ltr})
      : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool autofocus;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: Theme.of(context).textTheme.titleLarge,
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        hintText: "Title",
        border: InputBorder.none,
      ),
      onChanged: (text) {
        onChanged?.call();
      },
      autofocus: autofocus,
      textDirection: textDirection,
    );
  }
}
