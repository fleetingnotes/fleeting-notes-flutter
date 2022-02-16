import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/constants.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.onSave,
    required this.onDelete,
    this.title = '',
  }) : super(key: key);

  final VoidCallback? onSave;
  final VoidCallback onDelete;
  final String title;

  void _onBack(context) {
    if (onSave != null) {
      onSave!();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed:
                (Navigator.canPop(context)) ? () => _onBack(context) : null,
          ),
          SizedBox(width: kDefaultPadding / 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (Responsive.isMobile(context))
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: onSave,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text("Delete"),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
