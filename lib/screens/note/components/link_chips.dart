import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';

class LinkChips extends StatelessWidget {
  const LinkChips({
    Key? key,
    required this.links,
    required this.onLinkPress,
  }) : super(key: key);

  final List links;
  final Function onLinkPress;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: links.isNotEmpty,
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: Theme.of(context).custom.kDefaultPadding / 3),
        child: Wrap(
          spacing: Theme.of(context).custom.kDefaultPadding / 3,
          children: [
            ...links.take(3).map((e) => ActionChip(
                  label: Text("[[$e]]"),
                  onPressed: () => onLinkPress(e),
                ))
          ],
        ),
      ),
    );
  }
}
