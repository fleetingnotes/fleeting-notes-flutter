import 'package:flutter/material.dart';

class SettingsTitle extends StatelessWidget {
  final String title;

  const SettingsTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
