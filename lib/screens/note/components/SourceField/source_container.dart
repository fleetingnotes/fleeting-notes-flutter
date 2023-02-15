import 'dart:async';

import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_preview.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/url_metadata.dart';

class SourceContainer extends ConsumerStatefulWidget {
  const SourceContainer({
    Key? key,
    this.controller,
    this.text,
    this.onChanged,
    this.overrideSourceUrl = false,
    this.readOnly = false,
  }) : super(key: key);

  final String? text;
  final TextEditingController? controller;
  final VoidCallback? onChanged;
  final bool overrideSourceUrl;
  final bool readOnly;

  @override
  ConsumerState<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends ConsumerState<SourceContainer> {
  TextEditingController controller = TextEditingController();
  Timer? saveTimer;
  UrlMetadata? metadata;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? controller;
    final sourceUrl = widget.text ?? controller.text;
    controller.text = sourceUrl;
    updateMetadata(sourceUrl, msDelay: 0);
  }

  void updateMetadata(url, {int msDelay = 3000}) {
    final db = ref.read(dbProvider);
    saveTimer?.cancel();
    saveTimer = Timer(Duration(milliseconds: msDelay), () async {
      var m = await db.supabase.getUrlMetadata(url);
      setState(() {
        metadata = m;
      });
    });
  }

  void clearSource() {
    setState(() {
      metadata = null;
      controller.text = '';
      widget.onChanged?.call();
    });
  }

  void onPressedPreview(String url) {
    Uri uri = Uri.parse(url);
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final noteUtils = ref.watch(noteUtilsProvider);
    final m = metadata;

    if (m != null) {
      return SourcePreview(
        metadata: m,
        onPressed: () => onPressedPreview(m.url),
        onClear: clearSource,
      );
    }
    return TextField(
      readOnly: widget.readOnly,
      style: Theme.of(context).textTheme.bodyMedium,
      controller: controller,
      onChanged: (text) {
        updateMetadata(text);
        widget.onChanged?.call();
      },
      decoration: InputDecoration(
        hintText: "Source",
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Open URL',
            icon: const Icon(Icons.open_in_new),
            onPressed: (controller.text == '')
                ? null
                : () => noteUtils.launchURLBrowser(controller.text, context),
          ),
        ),
      ),
    );
  }
}
