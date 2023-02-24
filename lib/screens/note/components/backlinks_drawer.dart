import 'package:fleeting_notes_flutter/screens/main/components/side_rail.dart';
import 'package:flutter/material.dart';

class BacklinksDrawer extends StatelessWidget {
  const BacklinksDrawer({
    Key? key,
    this.title = '',
    this.closeDrawer,
    this.width,
  }) : super(key: key);

  final String title;
  final VoidCallback? closeDrawer;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: NavigationDrawer(
        onDestinationSelected: (v) => onDestinationSelected(context, v),
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    'Backlinks',
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
                  IconButton(
                    onPressed: closeDrawer,
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
