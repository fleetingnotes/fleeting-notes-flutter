import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onPressed;

  const InfoCard({
    super.key,
    this.title = '',
    this.description = '',
    this.buttonText = '',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(description, style: textTheme.bodySmall, softWrap: true),
                  const SizedBox(height: 8),
                  SelectionContainer.disabled(
                    child: FilledButton(
                      child: Text(buttonText),
                      onPressed: onPressed,
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
