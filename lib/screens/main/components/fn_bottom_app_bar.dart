import 'package:flutter/material.dart';

class FNBottomAppBar extends StatelessWidget {
  const FNBottomAppBar({
    super.key,
    required this.isElevated,
    required this.isVisible,
    this.onRecord,
    this.onAddChecklist,
    this.onImagePicker,
  });

  final bool isElevated;
  final bool isVisible;
  final VoidCallback? onRecord;
  final VoidCallback? onAddChecklist;
  final VoidCallback? onImagePicker;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isVisible ? 80.0 : 0,
      child: BottomAppBar(
        elevation: isElevated ? null : 0.0,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.check_box_outlined),
              onPressed: onAddChecklist,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.mic_outlined),
              onPressed: onRecord,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.photo_outlined),
              onPressed: onImagePicker,
            ),
          ],
        ),
      ),
    );
  }
}
