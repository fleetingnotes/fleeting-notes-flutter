import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final String name;
  final String description;
  final Widget? leading;
  final List<Widget>? actions;

  const SettingsItem(
      {super.key,
      this.name = '',
      this.description = '',
      this.actions,
      this.leading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        Row(
          children: [
            if (leading != null)
              Padding(padding: const EdgeInsets.only(right: 8), child: leading),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    )
                ],
              ),
            ),
            ...?actions?.map((a) =>
                Padding(padding: const EdgeInsets.only(left: 8), child: a)),
          ],
        ),
      ],
    );
  }
}
