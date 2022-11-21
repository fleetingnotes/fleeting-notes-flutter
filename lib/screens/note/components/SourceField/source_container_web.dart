import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart'
    as sc;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SourceContainer extends ConsumerStatefulWidget {
  const SourceContainer({
    Key? key,
    required this.controller,
    this.onChanged,
    this.overrideSourceUrl = false,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool overrideSourceUrl;

  @override
  ConsumerState<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends ConsumerState<SourceContainer> {
  bool sourceFieldVisible = !kIsWeb;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    setState(() {
      sourceFieldVisible = widget.controller.text.isNotEmpty || !kIsWeb;
    });
    bool fillSource = settings.get('auto-fill-source') ?? false;
    if (fillSource && widget.overrideSourceUrl) {
      setSourceUrl();
    }
  }

  void setSourceUrl() async {
    widget.controller.text = await BrowserExtension()
        .getSourceUrl(defaultText: widget.controller.text);
    widget.onChanged?.call();
    setState(() {
      sourceFieldVisible = true;
    });
  }

  sc.SourceContainer sourceContainer() {
    return sc.SourceContainer(
      controller: widget.controller,
      onChanged: widget.onChanged,
      overrideSourceUrl: widget.overrideSourceUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child:
          (widget.controller.text.isNotEmpty || !kIsWeb || sourceFieldVisible)
              ? sourceContainer()
              : TextButton(
                  onPressed: setSourceUrl,
                  child: const Text('Add Source URL'),
                ),
    );
  }
}
