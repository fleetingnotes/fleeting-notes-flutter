import 'package:fleeting_notes_flutter/responsive.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/constants.dart';

class Header extends StatelessWidget {
  const Header({
    Key? key,
    required this.onSave,
    required this.onDelete,
    required this.onSearch,
    this.title = '',
  }) : super(key: key);

  final Function? onSave;
  final VoidCallback onDelete;
  final VoidCallback onSearch;
  final String title;

  void _onBack(context) {
    // if (onSave != null) {
    //   onSave!();
    // }
    Navigator.of(context).pop();
  }

  void newSave(context) async {
    String errMessage = await onSave!();
    if (errMessage != '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errMessage),
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved'),
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
            icon: const Icon(Icons.arrow_back),
            onPressed:
                (Navigator.canPop(context)) ? () => _onBack(context) : null,
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),
            onPressed: onSave == null ? null : () => newSave(context),
          ),
          if (Responsive.isMobile(context))
            IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
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
