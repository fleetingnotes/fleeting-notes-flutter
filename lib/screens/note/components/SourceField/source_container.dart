import 'dart:async';

import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/url_metadata.dart';

class SourceContainer extends ConsumerStatefulWidget {
  const SourceContainer({
    Key? key,
    this.controller,
    this.text,
    this.metadata,
    this.onChanged,
    this.onClearSource,
    this.readOnly = false,
  }) : super(key: key);

  final String? text;
  final UrlMetadata? metadata;
  final TextEditingController? controller;
  final VoidCallback? onChanged;
  final VoidCallback? onClearSource;
  final bool readOnly;

  @override
  ConsumerState<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends ConsumerState<SourceContainer> {
  TextEditingController controller = TextEditingController();
  Timer? saveTimer;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? controller;
    final sourceUrl = widget.text ?? controller.text;
    controller.text = sourceUrl;
  }

  void onPressedPreview(String url) {
    Uri uri = Uri.parse(url);
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    if (m != null) {
      return SourcePreview(
        metadata: m,
        onPressed: () => onPressedPreview(m.url),
        onClear: widget.onClearSource,
      );
    }
    return TextField(
        readOnly: widget.readOnly,
        style: Theme.of(context).textTheme.bodySmall,
        controller: controller,
        onChanged: (text) => widget.onChanged?.call(),
        decoration: const InputDecoration(
          isDense: true,
          hintText: "Source",
          border: InputBorder.none,
        ));
  }
}
