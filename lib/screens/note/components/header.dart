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

  final Function? onSave;
  final VoidCallback onDelete;
  final String title;

  void _onBack(context) {
    if (onSave != null) {
      onSave!();
    }
    Navigator.of(context).pop();
  }

  void newSave(context) async {
    String errMessage = await onSave!();
    if (errMessage != '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMessage),
        duration: Duration(seconds: 2),
      ));
    }
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
            onPressed: onSave == null ? null : () => newSave(context),
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
