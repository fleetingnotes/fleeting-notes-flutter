import 'dart:io';

import 'package:flutter/foundation.dart';
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
    var height = (!kIsWeb && Platform.isIOS) ? 100.0 : 80.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isVisible ? height : 0,
      child: BottomAppBar(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.check_box_outlined),
              onPressed: onAddChecklist,
            ),
            IconButton(
              icon: const Icon(Icons.mic_outlined),
              onPressed: onRecord,
            ),
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
