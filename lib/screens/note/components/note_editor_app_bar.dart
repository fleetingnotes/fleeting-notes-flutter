import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/Note.dart';
import '../../../services/providers.dart';
import 'note_popup_menu.dart';

class NoteEditorAppBar extends ConsumerWidget {
  const NoteEditorAppBar({
    super.key,
    required this.note,
    this.elevation,
    this.title,
    this.onClose,
    this.onBacklinks,
    this.contentController,
    this.titleController,
  });

  final Note? note;
  final VoidCallback? onClose;
  final VoidCallback? onBacklinks;
  final double? elevation;
  final Widget? title;
  final TextEditingController? contentController;
  final TextEditingController? titleController;

  void _onShare(BuildContext context) async {
    if (kIsWeb) {
      await Clipboard.setData(
          ClipboardData(text: contentController?.text ?? ''));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("Copied Note Content"),
        showCloseIcon: true,
      ));
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      contentController?.text ?? '',
      subject: titleController?.text,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final n = note;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          const Spacer(),
          NotePopupMenu(
            note: note,
            onAddAttachment: (String fn, Uint8List? fb) {
              if (n == null) return;
              noteUtils.onAddAttachment(context, n, fn, fb,
                  controller: contentController);
            },
            onShare: () => _onShare(context),
          ),
          if (onBacklinks != null)
            OutlinedButton(
              onPressed: onBacklinks,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Backlinks'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
